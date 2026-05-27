# Workout-Tracker Uygulaması: Gelir Modeli ve Özellik Planı

Uygulamanın mevcut kaynak kodunu (özellikle `screens`, `models` klasörlerindeki yapıları, istatistikleri ve rutin oluşturma özelliklerini) inceledikten sonra, stratejiniz doğrultusunda Google Play'de yayınlamak üzere aşağıdaki **Freemium (Ücretsiz + Abonelik)** ve **Premium (Pro - Ücretli Uygulama)** yapısını öneriyorum.

## 1. Normal Sürüm (Ücretsiz - Reklamlı)
Bu sürüm, kullanıcıların uygulamayı deneyimlemesini ve alışkanlık kazanmasını hedefler, ancak bazı kısıtlamalar ve reklamlar barındırır.

- **Reklamlar:**
  - Ekran altlarında **Banner Reklamlar** (Örn: Home, Plans ve Stats ekranlarında).
  - İsteğe bağlı / araya giren **Geçiş (Interstitial) Reklamlar** (Örn: Bir antrenmanı bitirip "Workout Summary" ekranına geçerken veya yeni bir rutin oluşturduğunda).
- **Rutin ve Plan Kısıtlaması:** 
  - Kullanıcı en fazla **2 veya 3 adet özel antrenman (Custom Routine)** oluşturabilir (`create_routine_screen.dart`).
- **Basit İstatistikler:**
  - `stats_screen.dart` içerisinde sadece **"Bu Hafta (Week)"** veya **"Bu Ay (Month)"** verileri görüntülenebilir. "Tüm Zamanlar (All Time)" veya detaylı kas hacim grafikleri kilitli olabilir.
- **Egzersiz Kütüphanesi:**
  - Genel temel egzersizlere erişim açıktır. Ancak bazı "Pro (İleri Seviye)" egzersizler kilitli tutulabilir veya hepsine erişim verilebilir (Bu durum kullanıcı tutunmasını artırabilir).

---

## 2. Normal Sürüm İçi Abonelik (Premium Özellikler)
Kullanıcılar normal sürümün içinden aylık veya yıllık abonelik aldığında (In-App Purchases) reklamlar kalkar ve tüm yetkiler açılır.

- **Reklamların Kaldırılması:** Uygulama tamamen reklamsız (Ad-Free) hale gelir.
- **Sınırsız Rutin Oluşturma:** Kullanıcı takviminin her günü için sınırsız sayıda program ve rutin oluşturabilir (`plans_screen.dart`).
- **Gelişmiş İstatistikler & Analizler:** 
  - `StatsScreen` içerisindeki tüm zamanlara ait detaylı grafiklere (Top Egzersizler, Hacim kayıtları, Ortalama istatistik hesaplamaları) tam erişim. 
- **1RM (One Rep Max) Analizi:** `exercise_info_screen.dart` üzerinde kullanıcının performansına göre 1 Tekrar Maksimum (1RM) gelişimi takibi açılır.
- *(Gelecekte Eklenebilir)*: Bulut yedekleme (Cloud Sync), hazır pro antrenman planları veya Excel/PDF ile antrenman verisi dışa aktarma (Export) özelliği eklenebilir.

---

## 3. Pro Sürüm (Tek Seferlik Ücretli Uygulama - Paid App)
Bu, Google Play'de ayrı bir APK (örneğin: `Workout Tracker Pro`) olarak listelenecek uygulamadır.

- Abonelik mantığı sevmeyen kullanıcılar için **tek seferlik yüksek bir ücretle** satılır.
- Kurulduğu anda uygulamanın **içerisinde hiçbir reklam kodu (SDK) barındırmaz** (Performans ve batarya ömrü olarak daha iyidir).
- Normal Sürümdeki tüm **Abonelikli** özelliklerin hepsi bu sürümde başından itibaren açık gelir.
- **Tavsiye:** İçerisinde "Normal sürüme" veri aktarma (Import/Export JSON veya SQLite) eklerseniz, Normal sürümden Pro sürüme geçen kullanıcılar verilerini kaybetmez.

---

### Nasıl Uygulanmalı? (Teknik Yol Haritası)

1. **RevenueCat / Glassfy Geçişi:** Abonelikleri kolayca yönetmek için `revenuecat` paketini projenize ekleyebilirsiniz. Uygulama açılışında kullanıcının `isPro` değişkenini `SettingsProvider` veya yeni bir `SubscriptionProvider` içine çekebilirsiniz.
2. **Google AdMob:** `google_mobile_ads` paketini ekleyip, `BannerAd` widget'ları ve `InterstitialAd` çağrıları için bir `AdService` klasörü hazırlamalısınız. Premium ise bu servis `null` döner.
3. **Flutter Flavors:** Ücretsiz ve "Pro Sürüm" olmak üzere iki ayrı Google Play uygulaması yayınlayacağınız için kodları ayırmak yerine **Flutter Flavors (Tatlar)** kullanarak aynı kod tabanından (*com.app.workout* ve *com.app.workout.pro*) olmak üzere iki ayrı çıktı almalısınız.

Özetle, analizlerime göre mevcut yapınız kısıtlamalar koymak (Örn: `if(!isPro && plans.length >= 2) return premium_go_screen;`) için son derece müsait bir mimaridedir.
