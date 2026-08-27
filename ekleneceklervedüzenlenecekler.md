# 🚀 Yesevi Flutter Mobil Uygulaması: Web Paneli Entegrasyon ve Mimari Rehberi (V2)

Bu doküman, Flutter uygulamasının YeseviWeb SaaS yönetim paneliyle %100 izole ve güvenli çalışmasını sağlayacak **kesin mimari kuralları ve güncel Firestore veri şemalarını** içerir. Lütfen kodlamaya başlamadan önce tüm maddeleri dikkatlice okuyun ve birebir uygulayın.

## 🧱 1. Kesin Veri İzolasyonu (Multi-Tenant) Kuralı

Sistemimiz çoklu kurum (Firma X, Firma Y) destekli bir SaaS yapısıdır. **X firmasının personeli, Y firmasının kutularını veya ihtiyaç sahiplerini KESİNLİKLE görmemeli ve onların paneline veri yazamamalıdır.**

### 📌 1.1. Login ve State Yönetimi (Zorunlu)
- Personel giriş yaptıktan hemen sonra, `uid` kullanılarak Firestore `users` koleksiyonundan kullanıcının dokümanı okunmalıdır.
- Çekilen dokümandaki `kurum_id` (Örn: `0jzCnpNoASTBn9DFN4YM`) uygulamanın global State'inde (Provider, Riverpod, BLoC vb. ile) güvenli bir şekilde saklanmalıdır.

### 📌 1.2. Okuma ve Yazma (Query & Write) Kuralları
- **YAZMA (Add/Update):** Veritabanına yazılacak `boxes` ve `beneficiaries` koleksiyonlarındaki HER YENİ KAYDIN içine, State'teki bu `kurum_id` alanı zorunlu olarak eklenmelidir.
- **OKUMA (Get/Stream):** Mobil uygulamada haritada veya listede gösterilecek tüm sorgular **MUTLAKA** `.where('kurum_id', isEqualTo: stateKurumId)` filtresiyle yapılmalıdır. Bu filtre olmadan yapılan sorgular diğer derneklerin verilerini sızdıracağı için kesinlikle yasaktır.

---

## 🗄️ 2. Koleksiyon Şemaları (Veritabanı ile %100 Uyumlu)

Mevcut Firestore yapımıza göre mobil uygulamanın yazacağı dokümanlar aşağıdaki iskelette olmalıdır:

### 📦 2.1. `boxes` (Bağış Kutuları) Güncel Şema
Mobil uygulamadan yeni bir kutu bırakıldığında veya toplandığında aşağıdaki alanlar kullanılmalıdır:
```dart
{
  "kurum_id": "STRING (State'ten eklenecek - İzolasyon için ZORUNLU!)",
  "shopName": "STRING (Dükkan/Konum Adı - Örn: Ünlü Mamülleri)",
  "latitude": DOUBLE (Enlem),
  "longitude": DOUBLE (Boylam),
  "status": "STRING ('dropped' veya 'collected')",
  "droppedBy": "STRING (Kutuyu bırakan personelin adı/emaili)",
  "droppedAt": Timestamp (Kutunun bırakılma zamanı),
  "collectedBy": "STRING (Kutuyu toplayan personel - İlk eklemede null olabilir)",
  "collectedAt": Timestamp (Toplanma zamanı - İlk eklemede null olabilir),
  "donationAmount": INTEGER (Toplanan miktar - İlk eklemede 0 veya null)
}
```

---

## 📱 3. Flutter'a Eklenecek Yeni Modül: "İhtiyaç Sahipleri" Ekranı

Web panelinde `BeneficiariesPage` olarak hazırlanan altyapının mobil saha ekibi (Flutter) tarafı tasarlanmalıdır. İlgili Flutter Agent'in izlemesi, uygulaması ve kodlaması gereken iş adımları şunlardır:

1. **Yeni Ekran (Screen) Tasarımı ve Yönlendirme:**
   - Alt navigasyon barına (BottomNavigationBar) veya yan menüye (Drawer) "İhtiyaç Sahipleri" adında yeni bir sekme/sayfa ekleyin.
   - Bu ekranda, personelin aktif kurumuna (`kurum_id`) ait olan ihtiyaç sahipleri Firebase'den stream veya future yapısıyla List / Harita (Google Maps veya Leaflet/FlutterMap) üzerinde gösterilmelidir.

2. **Harita Üzerinden Lokasyon Seçme (Add Beneficiary):**
   - Sağ alt köşedeki (FAB) butonla yeni kişi ekleme ekranına veya modalına geçiş yapılmalıdır.
   - Kutularda yapıldığı gibi **Harita üzerinden ilgili lokasyona gelinerek bir nokta (marker) atılması** istenmelidir, böylece net (lat, lng) koordinatları elde edilir.

3. **Form ve Firestore Kaydı:**
   - Haritadan koordinat seçildikten sonra; Ad Soyad, Telefon, Adres açıklaması, İhtiyaç Durumu (Dropdown: Bekliyor, Acil, vs.) toplanmalıdır.
   - Form başarıyla doldurulduğunda, yukarıda (Madde 2.2) belirtilen `beneficiaries` koleksiyon şemasına **birebir uyularak** (içine Login state'indeki `kurum_id` yerleştirilerek) `FirebaseFirestore.instance.collection('beneficiaries').add(...)` işlemi yapılmalıdır.

***

**⚠️ Geliştirici Özel Notu:** Kodlamaya başlamadan önce `kurum_id` mantığının tüm repository (veri erişim) katmanlarınızdaki `GET`, `ADD`, `UPDATE` fonksiyonlarına sıkıca entegre edildiğinden emin olun. İzole edilmiş bir sorgu yapısı, SaaS güvenliğinin temelidir. Başarılar dileriz! 🚀