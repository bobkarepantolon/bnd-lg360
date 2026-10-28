# BND-LG360: LG 360 Cam (LGR105) Android 14+ / HyperOS Kontrolcüsü ve Medya Yöneticisi

Bu proje, orijinal LG 360 CAM uygulamasının modern Android sürümlerinde çökmesi ve çalışmaması nedeniyle, **Xiaomi Poco X7 Pro (Android 14+ / HyperOS)** başta olmak üzere tüm modern Android cihazlarda LG 360 Cam (LGR105) kamerasını tam fonksiyonel yönetmek üzere geliştirilmiş bağımsız bir Flutter projesidir.

---

## 🚀 Öne Çıkan Özellikler ve HyperOS Uyumluluğu

1. **Android 14+ İnternetsiz Wi-Fi Soket Kilidi (Network Bypassing):**
   - Xiaomi HyperOS, LG 360 Cam'in Wi-Fi ağına bağlandığında "Bu ağda internet yok" diyerek arka planda istekleri hücresel veriye yönlendirir.
   - Bu projede Kotlin tarafındaki `CameraNetworkManager.kt`, `ConnectivityManager.bindProcessToNetwork` kullanarak Dart'ın tüm HTTP/MJPEG trafiğini doğrudan kameranın `192.168.43.1` alt ağına kilitler.

2. **Canlı Vizör (Zero-Latency MJPEG Stream):**
   - `camera.getLivePreview` komutunun multipart bayt akışından JPEG sihirli baytları (Magic bytes `0xFF 0xD8` SOI ve `0xFF 0xD9` EOI) anlık taranarak 30 FPS'e varan akıcı önizleme sağlanır.

3. **360° Alt Kör Nokta (Nadir) Mühürleme Motoru:**
   - Eşdikdörtgensel (Equirectangular - 2:1 oranlı) fotoğrafların altındaki tripod/el görüntüsünü taban merkezli ($X = W/2, Y = H$) matematiksel formülle örter.
   - Çember yayına teğet açılı kavisli metin (örn. `bendelimiyim.com • BND 360`) çizer.
   - Android 14 Scoped Storage standardında doğrudan `DCIM/BND360` klasörüne kaydeder.

---

## 🛠️ APK Paketleme Seçenekleri

### Seçenek 1: GitHub Actions ile Otomatik APK Derleme (Önerilen - Bilgisayara Kurulum Gerekmez)
1. Bu proje klasörünü kendi GitHub hesabınızda bir repoya yükleyin.
2. Reponun **Actions** sekmesine gidin.
3. `.github/workflows/build-apk.yml` iş akışı otomatik olarak Flutter 3.24 ve Java 17 ile derlemeyi başlatacaktır.
4. Derleme bittiğinde (yaklaşık 2-3 dakika) **Artifacts** bölümünden `BND-LG360-Release-APK` dosyasını doğrudan telefonunuza indirin!

### Seçenek 2: Yerel Bilgisayarda Flutter CLI ile Derleme
```bash
cd bnd_lg360
flutter pub get
flutter build apk --release
```
Oluşan APK:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Xiaomi Poco X7 Pro (HyperOS) Kurulum ve Bağlantı Adımları

1. **APK Kurulumu:**
   - İndirdiğiniz `.apk` dosyasını telefonunuza yükleyin. Gerekirse "Bilinmeyen kaynaklardan yükle" iznini onaylayın.
2. **Kamerayı Açma:**
   - LG 360 Cam üzerindeki güç tuşuna basılı tutun. Üstteki iki LED yeşil yanınca Wi-Fi açma tuşuna basın.
3. **Wi-Fi Bağlantısı:**
   - Telefonunuzun Wi-Fi ayarlarından `LGR105_xxxxxx` ağına bağlanın.
   - Varsayılan Wi-Fi şifresi: Kameranın altındaki etiketinde yer alan Seri Numarasının son 8 hanesidir (veya `00` + son 6 hane).
4. **Xiaomi HyperOS Wi-Fi Ayarı:**
   - Bağlandığınızda "İnternet bağlantısı yok, yine de bağlı kalmak istiyor musunuz?" uyarısı çıkarsa **"Evet / Bağlı Kal"** seçeneğini seçin.
5. **Uygulamayı Açın:**
   - BND-LG360 uygulamasını başlatın. Uygulama otomatik olarak kamera soketine kilitlenecek ve canlı vizör açılacaktır!
