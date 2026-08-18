# Bağış Kutusu Takip Sistemi

Bu proje, sahada dağıtılan bağış kutularının (Yesevi Hareketi veya benzeri organizasyonlar için) konumlarını, durumlarını ve toplanan bağış miktarlarını takip etmek için geliştirilen modern ve minimalist bir Flutter uygulamasıdır.

## 🎯 Projenin Amacı
Bağış kutularının hangi firmaya bırakıldığı, kimin bıraktığı, ne zaman alındığı ve içinden ne kadar bağış çıktığı gibi verilerin merkezi bir sistemden anlık olarak harita ve liste üzerinden takip edilmesi.

## 🎨 Tasarım Sistemi (UI/UX)
Tasarım dili **minimalist, modern ve sade** olacaktır. Karmaşık arayüzlerden kaçınılacaktır.
*   **Ana Renkler (Primary Colors):** Yumuşak açık yeşil tonları (doğayı, yardımlaşmayı ve umudu temsil eden ferah bir yeşil) ve beyaz. (Logo uyumuna göre soft mavi dokunuşlar da eklenebilir).
*   **Arka Plan:** Tamamen beyaz (`#FFFFFF`) veya çok açık gri (`#F8F9FA`).
*   **Kartlar ve Butonlar:** Hafif gölgelendirmeli (soft shadow), köşeleri yuvarlatılmış (border-radius: 12px veya 16px) minimalist kart tasarımları.
*   **Tipografi:** Okunabilirliği yüksek, modern sans-serif fontlar (örn: Google Fonts'tan *Inter*, *Poppins* veya *Roboto*).
*   **İkonlar:** İçi boş, ince çizgili modern ikon setleri (Line icons).

## 🛠 Kullanılan Teknolojiler
*   **Geliştirme Ortamı:** Flutter & Dart
*   **Veritabanı & Backend:** Firebase (Firestore, Firebase Auth)
*   **State Management:** Riverpod (veya Provider - projenin ölçeğine göre tercih edilecek)
*   **Harita Servisi:** Google Maps API

## 📦 Temel Kütüphaneler
*   `firebase_core`, `firebase_auth`, `cloud_firestore`
*   `google_maps_flutter`, `geolocator`, `url_launcher`
*   `intl` (Tarih ve para birimi formatlamaları için)
*   `google_fonts` (Modern tipografi için)

## 📱 Sayfalar ve İşlevleri

### 1. Kullanıcı Girişi (Login View)
*   Saha çalışanlarının e-posta ve şifre ile sisteme giriş yapacağı ekran. Temiz, sadece logo ve iki input alanından oluşan sade bir tasarım.
*   Giriş yapmayan kullanıcılar sisteme erişemez.

### 2. Harita Sayfası (Map View) - (Ana Sayfa)
*   Dağıtılan tüm bağış kutularının harita üzerinde minimalist "Pin (Marker)" olarak gösterildiği ekran.
*   Pinlere tıklandığında alttan açılan (Bottom Sheet) şık bir bilgi kartı ile mekan adı ve durumu gösterilir.
*   Kullanıcı kendi konumunu görebilir ve kutuya yol tarifi almak için harici haritaya yönlendirilebilir.

### 3. Liste Sayfası (List View)
*   Kutuların firma/dükkan isimlerine göre modern kartlar halinde listelendiği sayfa.
*   Arama çubuğu (Search bar) ile dükkan ismine göre kutu aranabilir.
*   Filtreleme: "Bekleyenler" ve "Alınanlar" olarak listeyi sekmelere (Tab) ayırma.

### 4. Kutu İşlem Modalı (Action Bottom Sheet)
*   **Kutu Bırakırken:** Sisteme yeni kayıt eklenir. Mekan adı girilir, cihazdan anlık konum otomatik çekilir. Bırakan kişi ve tarih sisteme kaydedilir.
*   **Kutu Alınırken:** Mevcut kaydın statüsü güncellenir. Alan kişi, alınma tarihi ve içinden çıkan bağış miktarı sisteme işlenir.

### 5. Ayarlar ve Profil Sayfası (Settings View)
*   **Profil Bilgileri:** Sisteme giriş yapan personelin adı ve e-posta adresi.
*   **Güvenlik:** Şifre değiştirme bağlantısı.
*   **Oturum İşlemleri:** Güvenli bir şekilde "Çıkış Yap" (Logout) işlevi.
*   **Hesap Yönetimi:** "Hesabımı Sil" butonu (App Store kuralları gereği).

## 🚀 Geliştirme Adımları (Yol Haritası)

1.  **Klasör Mimarisi:** `lib` altında `features` (veya `views`), `core`, `models`, `services` gibi modüler bir yapının kurulması.
2.  **Tema Ayarları:** Açık yeşil ve beyaz ağırlıklı ThemeData'nın oluşturulması.
3.  **Firebase & Auth:** Firebase entegrasyonu ve Login sayfasının işlevsel hale getirilmesi.
4.  **Veritabanı Servisleri:** Firestore CRUD işlemlerinin yazılması.
5.  **Harita & GPS:** Google Maps entegrasyonu ve konum servislerinin ayarlanması.
6.  **Arayüz Tasarımları:** Harita, Liste ve Ayarlar sayfalarının koda dökülmesi.