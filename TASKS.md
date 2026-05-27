# Workout Tracker — Görev Listesi

> Son güncelleme: 20 Nisan 2026

---

## Görevler

### 27. ✅ MANAGE_EXTERNAL_STORAGE kaldırma + güvenli backup akışı
- [x] Backup/restore akışını dosya seçici tabanlı (SAF uyumlu) yönteme taşı
- [x] Settings ekranından depolama izin isteme mantığını kaldır
- [x] AndroidManifest içinden `MANAGE_EXTERNAL_STORAGE` ve legacy external storage izinlerini kaldır
- [x] Onboarding başlangıç izinlerinde depolama iznini devre dışı bırak
- [x] Analyze ve Android Kotlin derleme doğrulamasını çalıştır

### 26. ✅ Android 15 Play Console edge-to-edge uyarı iyileştirmesi
- [x] MainActivity'yi Android önerisine göre `enableEdgeToEdge()` akışına geçir
- [x] Native Android Kotlin derlemesini çalıştırıp doğrula
- [x] Play uyarı kaynaklarını mapping/usage çıktısında izole et (app code vs Flutter/plugin)
- [x] Bağımlılık güncellik durumunu kontrol et

### 25. 🏆 Trophy sistemini set bazlı yap
- [x] Trophy milestone mantığını reps yerine toplam set sayısına çevir
- [x] Achievement key/type değerlerini set bazlı güncelle
- [x] Stats ekranı trophy kartı progress ve etiketlerini set bazlı güncelle
- [x] EN/TR/ES trophy metinlerini set olarak güncelle
- [x] Analyze çalıştırıp doğrula

### 24. 🐛 Backup storage permission ayar yönlendirme düzeltmesi
- [x] Android 11+ için MANAGE_EXTERNAL_STORAGE manifest iznini ekle
- [x] Backup izin akışını Android sürümüne göre düzenle (manage/storage)
- [x] Open Settings aksiyonunu özel dosya erişimi akışına uygun hale getir
- [x] İzin metnini daha anlaşılır hale getir (EN/TR/ES)
- [x] Analyze çalıştırıp doğrula

### 23. ✅ Android 15 edge-to-edge uyumluluk düzeltmesi
- [x] Flutter tarafında sistem UI modunu edge-to-edge olarak ayarla
- [x] MainActivity'de Android edge-to-edge uyumluluğunu etkinleştir
- [x] Display cutout davranışını Android 15 önerisine göre güncelle
- [x] Android Kotlin derlemesini çalıştırıp doğrula

### 22. ✅ Play Store yorum popup + backup path fix
- [x] Review popup'ını startup yerine ilk antrenman tamamlandıktan sonra göster
- [x] Yıldız/yorum akışını uygulama içi review (in-app review) ile çalıştır
- [x] Yedekleme akışındaki PathNotFound hatasını kaldır
- [x] Backup dosyalarını ana dizinde `Workout Tracker` klasörüne yazacak şekilde güncelle
- [x] Restore dosya seçicisini backup klasörü başlangıç dizinine yönlendir
- [x] İlgili testleri/analyze çalıştır ve doğrula

### 21. 🚀 Stats redesign + streak + kupa sistemi
- [x] Movement highlights bölümünü Home ekranından kaldır, sadece Stats ekranında bırak
- [x] Stats ekranında kart yerleşimini responsive hale getir (kartlar ekrana düzgün otursun)
- [x] Toplam tekrar bazlı kupa sistemi ekle (50 / 100 / 1000 reps)
- [x] Programa uyum bazlı streak sistemi ekle (1 hafta / 2 hafta / 1 ay milestone)
- [x] Stats ekranını yeni streak + kupa alanlarıyla modernize et
- [x] Localization anahtarlarını güncelle (EN/TR/ES)
- [x] Test ve analiz çalıştır, TASKS/AGENT değişikliklerini güncelle

### 20. 🔧 Play release notes md otomatik güncelleme
- [x] Her otomatik AAB build çalıştığında `docs/play-release-notes.md` dosyasına güncel sürüm/tarih bilgisini yaz

### 19. 📝 Play sürüm notlarını md dosyasına yazma ✅
- [x] Çok dilli Play sürüm notlarını md dosyasına ekle

### 18. ✅ Paket adı ve manifest authority çakışma düzeltmesi
- [x] Android package id'yi `com.workouttracker.workout_tracker` olarak geri al
- [x] Namespace/MainActivity paketini aynı kimliğe hizala
- [x] AAB build alıp doğrula

### 17. 🚀 AAB build + otomatik sürüm artırma ✅
- [x] `pubspec.yaml` sürümünü artır (yeni release)
- [x] Yeni sürümle free flavor AAB build al
- [x] Her build öncesi sürümü otomatik artıran script ekle
- [x] Build akışını dokümante et (AGENT/TASKS güncelle)

### 16. 🚀 APK sahiplik doğrulama + free paket geçişi + soft-open + UI/i18n
- [x] Free flavor paket adını `com.workouttracker.app` olarak güncelle
- [x] `adi-registration.properties` dosyasını doğru konuma ekle ve snippet'i yaz
- [ ] Keystore SHA-256 parmak izini doğrula ve imzalı free release APK üret
- [x] Premium/paywall/reklam görünürlüğünü gizle, tüm özellikleri açık hale getir
- [x] Home highlights bölümüne hareket türü başına en iyi performans kartları ekle
- [x] Stats ekranını modern dashboard görünümüne güncelle
- [x] Çoklu dil karakter/encoding sorunlarını düzelt (özellikle Türkçe)
- [x] AGENT.md ve TASKS.md güncellemelerini tamamla

### 15. 🚀 Sürüm güncelleme ✅
- [x] `pubspec.yaml` sürümünü 3.1.14+27 olarak güncelle

### 14. 🚀 Sürüm güncelleme ✅
- [x] `pubspec.yaml` sürümünü 3.1.13+26 olarak güncelle

### 13. ✅ Dil uyumluluğu + BMI + Premium görünürlüğü
- [x] Türkçe ve Fransızca karakter bozulmalarını düzelt
- [x] Tüm dil desteklerini kontrol edip karakter uyumluluğunu tamamla
- [x] Body fat hesaplamasını düzelt
- [x] BMI'ye göre kilo durumu bilgisini ekle
- [x] Premium ibaresini yalnızca Home / Library / Stats / Workouts ana sayfasında göster

### 12. 📦 GitHub Release v3.0.1 ✅
- [x] Kas grubu kategorileri iyileştirildi (Arms→Biceps+Triceps, Legs→Quadriceps+Hamstrings, vb.)
- [x] Exercise timer fix: aktif görüntülenen egzersize süre yazılıyor
- [x] finishWorkout tüm açık egzersizleri kapatıyor
- [x] 60+ custom exercise name override + fuzzy matching + cache eklendi
- [x] Donut chart ortalandı, legend wrap center
- [x] v3.0.1+7 versiyon güncellendi
- [x] README.md güncellendi (v3.0.1 changelog)
- [x] Git commit & tag & push
- [x] GitHub release oluştur (v3.0.1 tag, APK yükle)

### 11. 📦 GitHub Release v3.0.0 ✅
- [x] ExRx.net yerine free-exercise-db (Unlicense, 873 egzersiz) entegrasyonu
- [x] `lib/utils/exercise_db.dart` oluşturuldu (ExrxUrlMatcher yerine)
- [x] `assets/data/free_exercises.json` eklendi (873 egzersiz verisi)
- [x] 8 Dart dosyası güncellendi (ExrxUrlMatcher → ExerciseDB)
- [x] `exrx_url_matcher.dart`, `exrx_exercises.json` ve 24+ Python script silindi
- [x] `url_launcher` bağımlılığı kaldırıldı
- [x] Egzersiz ekleme bug'ı düzeltildi (pick mode Map<String,String> dönüşü)
- [x] Otomatik resim geçişi eklendi (GIF-benzeri animasyon, 1.2s interval)
- [x] v3.0.0+6 olarak versiyon güncellendi
- [x] README.md güncellendi (free-exercise-db, 873 egzersiz, v3.0.0 changelog)
- [x] AGENT.md güncellendi

### 11. 📦 GitHub Release v3.0.0 ✅
- [x] Git commit & push
- [x] GitHub release oluştur (v3.0.0 tag, APK yükle)

### 1. 🔔 Bildirim Paneli — Aktif Antrenman Bildirimi ✅
- [x] `flutter_local_notifications` paketini ekle (`pubspec.yaml`)
- [x] Android izinleri ekle: `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `VIBRATE` (`AndroidManifest.xml`)
- [x] Android 13+ için runtime bildirim izni iste (antrenman başlatırken)
- [x] Antrenman başladığında persistent bildirim göster (ongoing, can't swipe away)
- [x] Bildirim içeriği: **Antrenman adı | Süre (5sn aralıkla güncellenen sayaç) | Son set bilgisi**
- [x] Antrenman bittiğinde / iptal edildiğinde bildirimi kaldır
- [x] `NotificationService` singleton oluşturuldu: `lib/services/notification_service.dart`

### 2. 🏃 Cardio Egzersizleri — Sadece Süre Sistemi ✅
- [x] Cardio algılama genişletildi: bike, run, treadmill, cycling, rowing, elliptical, jump rope, swimming, stair, walk + TR çevirileri
- [x] Active workout ekranında cardio: weight/reps input gizlendi, büyük timer gösterimi eklendi
- [x] Start/Stop butonuyla cardio timer kontrolü eklendi
- [x] "Save (X min)" butonuyla süre kaydedme eklendi
- [x] Provider'da `_activeCardioTimerIds` ile bağımsız cardio timer takibi

### 3. 🎨 Active Workout Ekranı — Arayüz İyileştirmeleri ✅
- [x] **Cancel butonu** AppBar popup menüsünden çıkarıldı → bottom bar'a taşındı (kırmızı)
- [x] **Library butonu** bottom bar'dan kaldırıldı
- [x] Bottom bar düzeni: `[Cancel (kırmızı)] [Add Exercise (mor, expanded)] [Finish (yeşil)]`

### 4. 📊 Home Screen — Muscle Groups Sıralama ✅
- [x] Muscle Group Distribution, Weekly Overview'ın üstüne taşındı
- [x] Yeni sıra: Calendar → Workouts → Next Training → **Muscle Groups** → Weekly Overview → Calories

### 5. 💾 Backup — Depolama İzinleri ✅
- [x] `permission_handler` ^11.3.1 eklendi (`pubspec.yaml`)
- [x] Android izinleri eklendi: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`
- [x] Backup öncesi runtime depolama izni isteniyor
- [x] İzin reddedilirse "Open Settings" aksiyonlu SnackBar gösteriliyor
- [x] Backup dosya adına timestamp eklendi: `workout_backup_YYYY-MM-DD_HHMM.db`

### 6. ⏱️ Süre (Timer) Sorunu ✅
- [x] `didChangeAppLifecycleState` wall-clock compensation mevcut ve çalışıyor
- [x] Notification sistemi ile kullanıcı arka planda da süreyi bildirimden takip edebilir
- [x] Cardio timer'ları bağımsız çalışıyor (aynı anda birden fazla cardio egzersiz zamanlayıcısı)

### 7. 📈 Exercise Details — Chart Butonu Kaldır ✅
- [x] `exercise_info_screen.dart` — 'Chart >' GestureDetector silindi
- [x] HISTORY başlığı tek başına düzgün gösteriliyor

### 8. ✅ Antrenman Tamamlanma Yüzdesi Düzeltmesi ✅
- [x] `active_workout_screen.dart`: `completedSets` artık `ex.sets.where((s) => s.completed).length` ile hesaplanıyor
- [x] `workout_provider.dart` `finishWorkout()` ve `_finishCurrentWorkoutSilently()`: aynı formül kullanılıyor
- [x] Free workout: `totalPlannedSets = targetSets > 0 ? targetSets : ex.sets.length` (en az yapılan set sayısı)
- [x] İlerleme çubuğu ve kaydedilen yüzde aynı formülü kullanıyor

### 9. 🔢 Repeats Required — Son Girilen Değer Sorunu ✅
- [x] Öncelik sırası düzeltildi: 1) Plan targetReps → 2) Geçmiş son set reps → 3) Input alanı
- [x] Plan olmayan egzersizlerde geçmişteki son kaydedilen reps gösteriliyor

---

## Tamamlanma Durumu: 26/27

`flutter analyze`: ✅ Passed (explicit path: `C:\flutter\bin\flutter.bat`)

`flutter test test/streak_achievements_test.dart`: ✅ Passed (4 tests)

`flutter test test/startup_flow_service_test.dart`: ✅ Passed (7 tests)

---

## Değişen Dosyalar
- `lib/screens/settings_screen.dart` — backup/restore akışı izin istemsiz dosya seçici (`FilePicker.saveFile` / `pickFiles`) modeline taşındı; MANAGE/Storage izin kontrolleri kaldırıldı
- `android/app/src/main/AndroidManifest.xml` — `MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` izinleri kaldırıldı
- `lib/services/app_permission_service.dart` — başlangıç akışında depolama izni isteme devre dışı bırakıldı (`notRequired`)
- `TASKS.md` — görev 27 eklendi ve tamamlandı olarak güncellendi
- `android/app/src/main/kotlin/com/workouttracker/workout_tracker/MainActivity.kt` — `FlutterFragmentActivity + enableEdgeToEdge()` akışına geçirildi; Android önerisiyle hizalandı ve Kotlin derleme doğrulandı
- `AGENT.md` — kupa sistemi set bazlı ve Android native edge-to-edge implementasyonu güncel hale getirildi
- `TASKS.md` — görev 26 eklendi ve tamamlandı olarak güncellendi
- `lib/utils/streak_achievements.dart` — trophy milestone sabitleri set bazlı olacak şekilde `kSetMilestones` ve `setAchievementKey()` olarak güncellendi
- `lib/db/database_helper.dart` — all-time tamamlanan set sayısını dönen `getTotalCompletedSets()` metodu eklendi
- `lib/providers/workout_provider.dart` — `getStatsInsights()` içinde trophy unlock akışı reps yerine completed set sayısına geçirildi (`achievementType: 'sets'`, `sets_*` key)
- `lib/screens/stats_screen.dart` — trophy kartında progress, value label ve insight state set bazlı hale getirildi
- `lib/l10n/translations.dart` — EN/TR/ES trophy metinleri reps yerine sets/set/series olarak güncellendi
- `TASKS.md` — görev 25 eklendi ve tamamlandı olarak güncellendi
- `android/app/src/main/AndroidManifest.xml` — `MANAGE_EXTERNAL_STORAGE` izni eklendi (Android 11+ All files access akışı için)
- `lib/screens/settings_screen.dart` — backup izin kontrolü Android sürümüne göre ayrıldı; API 30+ için `manageExternalStorage` akışı ve retry/open settings davranışı düzeltildi
- `lib/l10n/translations.dart` — EN/TR/ES `storage_permission_required` metni Android 11+ all-files erişim gereksinimini net anlatacak şekilde güncellendi
- `TASKS.md` — görev 24 eklendi ve tamamlandı olarak güncellendi
- `android/app/src/main/kotlin/com/workouttracker/workout_tracker/MainActivity.kt` — `WindowCompat.setDecorFitsSystemWindows(window, false)` ile edge-to-edge etkinleştirildi; cutout mode Android 15 için korunarak derleme hatası giderildi
- `android/app/build.gradle.kts` — `androidx.activity:activity-ktx:1.9.1` bağımlılığı eklendi
- `lib/main.dart` — uygulama başlangıcında `SystemUiMode.edgeToEdge` etkinleştirildi
- `android/app/src/main/AndroidManifest.xml` — MainActivity için `windowLayoutInDisplayCutoutMode="always"` eklendi
- `AGENT.md` — Android 15 edge-to-edge uyumluluk notları ve Android bağımlılık tablosu güncellendi
- `TASKS.md` — görev 23 eklendi ve tamamlandı olarak güncellendi
- `lib/screens/settings_screen.dart` — yedekleme `FilePicker.saveFile` yerine doğrudan `Workout Tracker` klasörüne yazacak şekilde güncellendi; PathNotFound kaynağı kaldırıldı; restore picker başlangıç dizini backup klasörü oldu
- `lib/services/startup_flow_service.dart` — review prompt mantığı workout-completion tabanlı hale getirildi (ilk antrenman sonrası, sonra periyodik)
- `lib/services/store_launcher.dart` — mevcut uygulamanın Play Store listeleme ve yorum sayfasını açan yeni yardımcı metotlar eklendi
- `lib/screens/startup_gate.dart` — startup üzerindeki review popup akışı kaldırıldı
- `lib/screens/active_workout_screen.dart` — antrenman bitişinde review prompt kararını hesaplayıp summary ekranına taşıyan akış eklendi
- `lib/screens/workout_summary_screen.dart` — post-workout popup eklendi; in-app review ile yıldız+yorum akışı bağlandı
- `pubspec.yaml` — `in_app_review` bağımlılığı eklendi
- `lib/l10n/translations.dart` — EN/TR/ES için rate-review popup metin anahtarları eklendi
- `test/startup_flow_service_test.dart` — workout-completion tabanlı review prompt kuralları için test kapsamı genişletildi
- `TASKS.md` — görev 22 eklendi ve tamamlandı olarak güncellendi
- `lib/db/database_helper.dart` — veritabanı sürümü v15'e yükseltildi; `achievements` tablosu + streak/kupa aggregate query ve unlock metotları eklendi
- `lib/providers/workout_provider.dart` — `getStatsInsights()` eklendi; reps milestone + streak milestone unlock akışı provider seviyesinde bağlandı
- `lib/screens/home_screen.dart` — movement highlights state/hesap/render tamamen kaldırıldı (artık sadece Stats ekranında)
- `lib/screens/stats_screen.dart` — streak kartı, kupa rafı ve responsive movement highlights grid ile modern UI yeniden tasarlandı
- `lib/utils/streak_achievements.dart` — **YENİ** streak hesaplama ve milestone sabitleri helper dosyası eklendi
- `lib/l10n/translations.dart` — EN/TR/ES için streak-kupa metin anahtarları eklendi
- `test/streak_achievements_test.dart` — **YENİ** streak hesaplama birim testleri eklendi
- `TASKS.md` — görev 21 tamamlandı olarak güncellendi
- `AGENT.md` — stats redesign + streak/kupa altyapısı ve şema güncellemesi için proje referansı güncellendi
- `scripts/build_free_aab_auto_version.ps1` — otomatik sürüm artırma akışına `docs/play-release-notes.md` auto metadata güncellemesi eklendi
- `docs/play-release-notes.md` — auto-generated metadata marker bloğu eklendi (version/release name/updated)
- `TASKS.md` — görev 20 eklendi ve tamamlandı olarak güncellendi
- `docs/play-release-notes.md` — **YENİ** Play Console için çok dilli sürüm notları bloğu eklendi
- `TASKS.md` — görev 19 eklendi ve tamamlandı olarak güncellendi
- `android/app/build.gradle.kts` — namespace/default/free `applicationId` `com.workouttracker.workout_tracker` olarak güncellendi
- `android/app/src/main/kotlin/com/workouttracker/workout_tracker/MainActivity.kt` — package tanımı `com.workouttracker.workout_tracker` olarak güncellendi
- `docs/google_play_release_checklist.md` — free package id doğrulama satırı `com.workouttracker.workout_tracker` olarak düzeltildi
- `AGENT.md` — genel bakıştaki free flavor package id güncellendi
- `TASKS.md` — görev 18 tamamlandı olarak güncellendi
- `pubspec.yaml` — sürüm `3.1.15+28` olarak güncellendi
- `scripts/build_free_aab_auto_version.ps1` — **YENİ** her build öncesi patch+build numarası artırıp free AAB üreten otomasyon scripti
- `build_free_aab_auto.bat` — **YENİ** Windows tek-komut launcher (`scripts/build_free_aab_auto_version.ps1` çağırır)
- `AGENT.md` — klasör yapısı ve build komutları otomatik sürüm artırımlı AAB akışına göre güncellendi
- `TASKS.md` — görev 17 eklendi ve tamamlandı olarak güncellendi
- `pubspec.yaml` — sürüm `3.1.14+27` olarak güncellendi
- `pubspec.yaml` — sürüm `3.1.13+26` olarak güncellendi
- `lib/l10n/translations.dart` — mojibake/karakter bozulması için otomatik encoding onarımı + BMI/body composition çeviri anahtarları (EN/TR/ES/DE/FR)
- `lib/utils/body_composition.dart` — body fat hesaplama formülü iyileştirildi, BMI + kilo durumu sınıflandırması eklendi
- `lib/screens/stats_screen.dart` — body composition kartı lokalize edildi, BMI ve kilo durumu gösterimi eklendi
- `lib/screens/settings_screen.dart` — body ölçü girişinde locale uyumlu sayı parse (virgül/feet-inch), yükseklik birimi düzeltmesi, premium badge kaldırıldı
- `lib/screens/home_screen.dart` — bozuk ayraç karakterleri düzeltildi (`•`)
- `lib/screens/active_workout_screen.dart` — premium badge kaldırıldı
- `lib/screens/exercise_info_screen.dart` — premium badge kaldırıldı
- `lib/screens/workout_detail_screen.dart` — premium badge kaldırıldı
- `lib/screens/create_routine_screen.dart` — premium badge kaldırıldı
- `lib/screens/paywall_screen.dart` — premium badge kaldırıldı
- `lib/screens/plans_screen.dart` — premium badge kaldırıldı
- `lib/screens/workout_schedule_screen.dart` — premium badge kaldırıldı
- `AGENT.md` — teknik borç/sorunlar bölümü güncellendi (dil uyumu, body fat, premium görünürlüğü)
- `TASKS.md` — görev 13 eklendi ve tamamlandı olarak güncellendi
- `android/app/build.gradle.kts` — free flavor package id `com.workouttracker.app` olarak güncellendi
- `android/app/src/main/assets/adi-registration.properties` — sahiplik doğrulama snippet'i eklendi
- `android/app/src/main/kotlin/com/workouttracker/workout_tracker/MainActivity.kt` — package tanımı `com.workouttracker.app` olarak güncellendi
- `lib/providers/monetization_provider.dart` — soft-open modu eklendi (premium açık, reklam/paywall gizli)
- `lib/widgets/entitlement_badge.dart` — soft-open modunda badge aksiyonları gizlendi
- `lib/screens/startup_gate.dart` — soft-open modunda startup offer atlandı
- `lib/screens/settings_screen.dart` — soft-open modunda premium bölümü gizlendi
- `lib/screens/stats_screen.dart` — dashboard metinleri lokalize edildi, movement highlights ve modern UI iyileştirildi
- `lib/screens/home_screen.dart` — hareket türü başına highlights kartları eklendi
- `lib/l10n/translations.dart` — EN/TR/ES için startup offer + body composition + yeni stats/home anahtarları eklendi
- `lib/providers/settings_provider.dart` — bozuk karakterli yorum satırları temizlendi
- `docs/google_play_release_checklist.md` — free package id `com.workouttracker.app` olarak güncellendi
- `scripts/sign_for_play_ownership.ps1` — **YENİ** hedef fingerprint doğrulamalı tek komutla imzalama scripti eklendi
- `pubspec.yaml` — versiyon 3.0.0+6, url_launcher kaldırıldı
- `lib/utils/exercise_db.dart` — **YENİ** free-exercise-db utility
- `assets/data/free_exercises.json` — **YENİ** 873 egzersiz verisi
- `lib/screens/exercise_info_screen.dart` — imageUrls, auto-cycling Timer, AnimatedSwitcher
- `lib/screens/exercise_library_screen.dart` — ExerciseDB, pick mode bug fix
- `lib/screens/swipeable_exercise_screen.dart` — ExerciseDB geçişi
- `lib/screens/workout_detail_screen.dart` — ExerciseDB geçişi
- `lib/screens/home_screen.dart` — ExerciseDB geçişi
- `lib/providers/workout_provider.dart` — ExerciseDB geçişi
- `lib/widgets/exercise_thumbnail.dart` — ExerciseDB, image_url
- `README.md` — v3.0.0 changelog, free-exercise-db bilgisi
- `AGENT.md` — free-exercise-db, şema v13, bağımlılık güncelleme
- **Silinen:** `exrx_url_matcher.dart`, `exrx_exercises.json`, 24+ Python script
