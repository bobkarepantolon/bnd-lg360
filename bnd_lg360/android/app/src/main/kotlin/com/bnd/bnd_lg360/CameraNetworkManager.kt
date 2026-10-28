package com.bnd.bnd_lg360

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.util.Log

/**
 * Xiaomi Poco X7 Pro (Android 14+ / HyperOS) için Özel Wi-Fi Soket Yöneticisi.
 *
 * Problem: Telefon, LG 360 Cam Wi-Fi ağına (192.168.43.1) bağlandığında
 * "İnternet bağlantısı yok" uyarısı verir ve mobil veri (4G/5G) aktifse
 * HTTP isteklerini mobil veriye yönlendirir.
 *
 * Çözüm: NetworkRequest ile NET_CAPABILITY_INTERNET zorunluluğunu kaldırıp
 * sadece TRANSPORT_WIFI talep edilir ve ConnectivityManager.bindProcessToNetwork
 * çağrısı yapılarak Flutter/Dart'ın tüm HTTP/MJPEG soketleri kameraya kilitlenir.
 */
class CameraNetworkManager(private val context: Context) {

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var isBound = false

    /**
     * İnternetsiz yerel kamera Wi-Fi ağını yakalar ve uygulamanın tüm soketlerini
     * bu ağa bağlar (bindProcessToNetwork).
     */
    fun bindToCameraWifi(onBoundSuccess: () -> Unit, onError: (String) -> Unit) {
        if (isBound) {
            Log.d("BND_Network", "Uygulama zaten kamera Wi-Fi ağına kilitlenmiş durumda.")
            onBoundSuccess()
            return
        }

        // İnternet zorunluluğu (NET_CAPABILITY_INTERNET) OLMAYAN sadece Wi-Fi taşıyıcısını talep ediyoruz
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) // Kritik nokta: İnternet aranmaz
            .build()

        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                super.onAvailable(network)

                val capabilities = connectivityManager.getNetworkCapabilities(network)
                val isWifi = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true

                if (isWifi) {
                    // Android 6.0 (API 23) ve sonrası için tüm process'i bu ağa kilitler
                    val success = connectivityManager.bindProcessToNetwork(network)
                    if (success) {
                        isBound = true
                        Log.d("BND_Network", "Uygulama başarıyla kamera Wi-Fi ağına (192.168.43.1) bağlandı.")
                        onBoundSuccess()
                    } else {
                        Log.e("BND_Network", "Ağ bağlantısı process'e kilitlenemedi.")
                        onError("Ağ bağlantısı process'e kilitlenemedi.")
                    }
                }
            }

            override fun onLost(network: Network) {
                super.onLost(network)
                Log.d("BND_Network", "Kamera Wi-Fi bağlantısı koptu.")
                unbind()
            }

            override fun onUnavailable() {
                super.onUnavailable()
                Log.w("BND_Network", "Kamera Wi-Fi ağı bulunamadı.")
                onError("Kamera Wi-Fi ağı bulunamadı. Lütfen telefonunuzun LG 360 Cam Wi-Fi'ına bağlı olduğundan emin olun.")
            }
        }

        try {
            connectivityManager.requestNetwork(request, networkCallback!!)
        } catch (e: Exception) {
            Log.e("BND_Network", "Ağ isteği hatası: ${e.localizedMessage}")
            onError("Ağ isteği başlatılamadı: ${e.localizedMessage}")
        }
    }

    /**
     * Kamera ile işlem bittiğinde soket kilidini kaldırır,
     * telefonun normal internete ve hücresel veriye dönmesini sağlar.
     */
    fun unbind() {
        if (isBound) {
            try {
                connectivityManager.bindProcessToNetwork(null)
                isBound = false
                Log.d("BND_Network", "Process ağ kilidi kaldırıldı, varsayılan ağa dönüldü.")
            } catch (e: Exception) {
                Log.e("BND_Network", "Ağ serbest bırakma hatası: ${e.message}")
            }
        }
        networkCallback?.let {
            try {
                connectivityManager.unregisterNetworkCallback(it)
            } catch (e: Exception) {
                Log.e("BND_Network", "Callback sonlandırma hatası: ${e.message}")
            }
            networkCallback = null
        }
    }
}
