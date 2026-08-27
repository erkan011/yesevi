# SaaS Destekli Web Yönetim Paneli - Yol Haritası ve Geliştirme Planı

## 1. Proje Özeti
Bu proje, mevcut Flutter mobil uygulamamızla aynı Firebase veritabanını paylaşacak olan SaaS (Hizmet Olarak Yazılım) tabanlı bir Web Yönetim Paneli'dir. Sistem **"Çoklu Kiracı" (Multi-tenant)** yapısında çalışacaktır. Sisteme giriş yapan her dernek veya vakıf, yalnızca kendi `kurum_id`'sine kayıtlı olan personelleri, bağış kutularını ve istatistikleri görebilecektir. Veri yalıtımı ve güvenliği projenin temel taşlarındandır.

## 2. Teknoloji Yığını
- **Frontend Yığını:** React (Vite kullanılarak oluşturulacak)
- **Stil ve Tasarım:** Tailwind CSS
- **Sayfa Yönlendirmeleri:** React Router DOM
- **Backend ve Veritabanı:** Firebase (Authentication ve Firestore)

## 3. Temel Modüller
- **Güvenli Giriş Sistemi:**
  - E-posta ve şifre ile güvenli kimlik doğrulama ekranı.
- **Dashboard (Kontrol Paneli):**
  - Kuruma ait toplam kutu sayısı, aktif personel sayısı ve kutuların genel durum (hasarlı, doluluk vb.) özetlerini gösteren istatistiksel kartlar ve grafikler.
- **Kutu Yönetimi:**
  - Sahadaki tüm bağış kutularının detaylı bir tabloda listelenmesi.
  - Kutuların konumlarının Google Maps veya Leaflet kullanılarak harita üzerinde görselleştirilmesi.
  - Sisteme yeni kutu ekleme veya mevcut kutuların bilgilerini/konumlarını düzenleme özellikleri.
- **Personel Yönetimi:**
  - Sahada kutu toplayan ve uygulamayı kullanan mobil uygulama kullanıcılarını (personelleri) sisteme ekleme ve sistemden çıkarma işlemleri.
- **Abonelik ve Finans (SaaS Modülü):**
  - SaaS mantığına uygun olarak kurumun sahip olduğu paket detayları, limit bilgileri ve ödeme/abonelik durumlarının sergileneceği sayfa.

## 4. Geliştirme Adımları (Ajan İçin Yol Haritası)
- **Adım 1: Proje Kurulumu ve Yapılandırma**
  - Vite ile React projesinin oluşturulması.
  - Tailwind CSS kurulumu ve yapılandırması.
  - Proje dizin yapısının (components, pages, context, vb.) oluşturulması.
- **Adım 2: Firebase ve Router Entegrasyonu**
  - Firebase SDK kurulumu ve yapılandırması (Firestore kuralları ve multi-tenant veri izolasyonu hazırlığı).
  - React Router DOM ile sayfa yapılarının ve rotaların kurulması.
- **Adım 3: Güvenli Giriş ve Yetkilendirme**
  - E-posta/şifre ekranının tasarımı ve Firebase Auth ile bağlanması.
- **Adım 4: Dashboard Tasarımı ve Veri Bağlantısı**
  - Sidebar ve Navbar gibi ortak layout bileşenlerinin üretilmesi.
  - Temel istatistiklerin Firestore'dan çekilip kartlara yansıtılması.
- **Adım 5: Kutu Yönetimi ve Harita Görünümü**
  - Kutu listeleme ve CRUD (Ekleme, Düzenleme, Silme) formları.
  - Leaflet / Google Maps kullanılarak kutu lokasyonlarının haritada işaretlenmesi.
- **Adım 6: Personel Yönetimi ve Abonelik (Finans)**
  - Sahadaki personelleri yönetme listesi ve fonksiyonelleri.
  - Limitler ve paket durumu için SaaS abonelik arayüzü.
- **Adım 7: Testler ve İyileştirmeler**
  - Kurumlar arası veri yalıtımının (kurum_id) sıkı bir şekilde test edilmesi.
  - Responsive (mobil uyumluluk) testleri ve UI iyileştirmeleri.

---

## 5. Firebase Yapılandırma Bilgileri

> ⚠️ **GÜVENLİK NOTU:** Gerçek API anahtarları asla `.md` veya kaynak kod dosyalarına yazılmamalıdır. Aşağıdaki bilgiler yalnızca referans amaçlıdır. Proje oluşturulduğunda anahtarlar `.env` dosyasında saklanacak ve `.gitignore`'a eklenecektir.

### Firebase Proje Bilgileri
| Alan                  | Değer                                    |
|-----------------------|------------------------------------------|
| **Proje ID**          | `yesevigaziantep`                        |
| **Proje Numarası**    | `632405116476`                           |
| **Storage Bucket**    | `yesevigaziantep.firebasestorage.app`    |
| **Android App ID**    | `1:632405116476:android:942756b7af70ec30a3e539` |
| **API Key**           | `AIzaSyA7K0p02JN6DoLbNbeoHMxSVOhD5POSAxc` |

### Web Paneli İçin .env Şablonu
Adım 1'de proje oluşturulduğunda aşağıdaki `.env` dosyası oluşturulacaktır:

```env
VITE_FIREBASE_API_KEY=AIzaSyA7K0p02JN6DoLbNbeoHMxSVOhD5POSAxc
VITE_FIREBASE_AUTH_DOMAIN=yesevigaziantep.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=yesevigaziantep
VITE_FIREBASE_STORAGE_BUCKET=yesevigaziantep.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=632405116476
VITE_FIREBASE_APP_ID=<Firebase Console'dan Web App eklendikten sonra alınacak>
```

### Yapılması Gereken Ek Adım
Firebase Console → Proje Ayarları → Genel sekmesinden **yeni bir Web Uygulaması** eklenmesi gerekecektir. Bu işlem sonucunda `appId` ve `measurementId` gibi web'e özel bilgiler elde edilecektir. Bu değerler `.env` dosyasına eklenecektir.
