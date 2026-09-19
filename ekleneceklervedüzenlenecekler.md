# 🚀 Yesevi Mobil (Flutter) - Senaryo Bazlı Güncelleme ve Hata Giderme Raporu

Bu doküman, saha operasyonu için belirlenen yeni senaryoya göre mobil uygulamaya eklenecek özellikleri ve mevcut hataların (bugfix) çözüm adımlarını içermektedir.

---

## 🛠️ BÖLÜM 1: Yeni Saha Senaryosu ve Geliştirmeler

### 1. Yeni Kutu Bırakma (Ekleme) İşlemi
* **Senaryo:** Saha personeli "+" butonuna tıklar, gerekli bilgileri ve fotoğrafı girer, "Kutuyu Bırak" der ve kutu haritaya düşer.
* **Nasıl Yapılacak:**
  * Kutu ekleme formuna şu alanlar eklenecek: `Mekan Adı`, `Mekan Numarası`, `Teslim Alan Kişi (İsim/Soyisim)`.
  * Forma **"Görsel Ekle"** (Kamera/Galeri) butonu entegre edilecek ve fotoğraf Firebase Storage'a yüklenip linki veritabanına kaydedilecek.
  * İşlem onaylandığında harita üzerinde yeni bir pin (yeşil) oluşturulacak.

### 2. Harita Üzerinde Pin Seçimi ve Aksiyonlar
* **Senaryo:** Haritadaki kutu pinine tıklandığında detaylar ve işlem butonları çıkar.
* **Nasıl Yapılacak:**
  * Pine tıklandığında alt kısımdan bir modal (BottomSheet) açılacak.
  * **Gösterilecek Bilgiler:** Bırakan personelin (İsim, Soyisim, Numara) ve Teslim Alan kişinin (İsim, Soyisim, Numara) bilgileri.
  * **Aksiyon Butonları:** Modal içerisinde 3 adet buton yer alacak: `[Kutuyu Boşalt]`, `[Kutuyu Al]`, `[Yol Tarifi]`.
  * *Yol Tarifi Butonu:* url_launcher paketi ile cihazın varsayılan harita uygulamasına (Google Maps/Apple Maps) enlem/boylam verisi gönderilerek rota çizdirilecek.

### 3. "Kutuyu Al" İşlemi ve Gider Girişi
* **Senaryo:** "Kutuyu Al" dendiğinde bağış miktarı ve yapılan giderler (yakıt vb.) girilir, kutu haritadan tamamen kaldırılır.
* **Nasıl Yapılacak:**
  * Butona basıldığında açılan formda `Bağış Miktarı`, `Gider Türü` (Örn: Yakıt, Diğer) ve `Gider Fiyatı` inputları olacak.
  * Veriler girilip onaylandığında Firestore'a kaydedilecek ve kutunun durumu `removed` (veya `collected_and_removed`) yapılarak haritadan **komple silinecek**.

### 4. "Kutuyu Boşalt" İşlemi
* **Senaryo:** "Kutuyu Boşalt" dendiğinde kutu yerinde kalır ancak haritadaki işareti sarı renge döner.
* **Nasıl Yapılacak:**
  * Butona basıldığında kutunun durumu `emptied` (veya `dropped_yellow`) olarak güncellenecek.
  * Harita ekranı bu durumu algılayıp pini yeşilden **sarı renge** çevirecek.

### 5. Kutular Sayfası (Liste) ve PDF Çıktısı
* **Senaryo:** Bekleyenler ve Alınanlar listesi olacak. Alınanlar detayında sadece giderlere özel PDF çıktısı alınabilecek.
* **Nasıl Yapılacak:**
  * Kutular sayfası iki sekmeye (Tab) ayrılacak: `Bekleyenler` ve `Alınanlar`.
  * Listeden bir elemana tıklandığında tüm detaylı bilgilerin yer aldığı bir Detay Sayfası açılacak.
  * **PDF Çıktısı:** Bu detay sayfasında yer alan gider bilgileri için `[Giderleri PDF Olarak İndir]` butonu eklenecek. `pdf` ve `printing` paketleri ile girilen gider kalemleri (yakıt vs.) ve tutarları tablo halinde PDF'e dönüştürülüp paylaşılacak/indirilecek.

### 6. Ayarlar ve Profil Sayfası
* **Senaryo:** Kullanıcı (personel) ayarlar sayfasında kendi kişisel bilgilerini görebilecek.
* **Nasıl Yapılacak:**
  * `Ayarlar / Profil` sayfasında veritabanından çekilen İsim, Soyisim, Telefon ve Kurum/Rol bilgileri listelenecek.

---

## 🐛 BÖLÜM 2: Hata Gidermeleri (Bugfix)
*(Mevcut hatalar ve planlanan çözüm yöntemleri)*

### 1. Uygulamanın Geç Açılması (Çift Harita Sorunu)
* **Hata:** Uygulama geç açılıyor. İki harita var, kaynağı ondan mı bak ve düzelt.
* **Nasıl Çözülecek:**
  * Harita bileşenleri "Lazy Load" (sadece ekranda göründüğünde yüklenme) mantığına geçirilecek.
  * Sekmeli bir yapı kullanılıyorsa, harita sekmeleri önceden değil, sadece kullanıcı o sekmeye tıkladığında `IndexedStack` ile render edilecek. Gereksiz arka plan harita yüklemeleri (Google Maps controller vs.) durdurulacak.

### 2. "Alınanlar" Kısmında Bilgi Kutucuklarına Tıklanabilirlik
* **Hata:** Bağış Kutuları sayfasında, Alınanlar kısmında bilgi kutucuklarına tıklandığında detaylı bilgi vermiyor.
* **Nasıl Çözülecek:**
  * Liste elemanları (ListTile veya Card widget'ları) bir `GestureDetector` veya `InkWell` içine alınacak.
  * Tıklanma (`onTap`) durumunda o kutunun tüm verilerini (Ne zaman bırakıldı, kim topladı, miktar, fotoğraf vs.) gösteren yeni bir detay sayfası (DetailScreen) veya geniş bir BottomSheet açılacak.

### 3. Geri Tuşu (Back Navigation) Hatası ve Haritaya Yönlendirme
* **Hata:** Bütün sayfalarda geriye çıktığımızda "Sayfa Bulunamadı" hatası veriyor. Bütün sayfalar kapandığında ana Harita sayfası açılsın.
* **Nasıl Çözülecek:**
  * Sayfalara `PopScope` widget'ı sarılarak Android'in fiziksel veya iOS'un kaydırma geri tuşu yakalanacak (intercept).
  * Geri tuşuna basıldığında uygulamayı hataya düşürmek (`Navigator.pop` ile boş stack'e düşmek) yerine, zorunlu olarak `Navigator.pushAndRemoveUntil(context, '/mapScreen', (route) => false)` komutu çalıştırılarak ana haritaya sorunsuz ve temiz bir dönüş garanti altına alınacak.