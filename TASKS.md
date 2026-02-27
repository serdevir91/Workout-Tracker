# Workout Tracker — Görev Listesi

> Son güncelleme: 27 Şubat 2026

---

## Görevler

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

## Tamamlanma Durumu: 9/9 ✅

`flutter analyze` sonucu: **No issues found!**

---

## Değişen Dosyalar
- `pubspec.yaml` — permission_handler, flutter_local_notifications eklendi
- `android/app/src/main/AndroidManifest.xml` — 7 yeni izin eklendi
- `lib/main.dart` — NotificationService.init() eklendi
- `lib/services/notification_service.dart` — **YENİ** bildirim servisi
- `lib/providers/workout_provider.dart` — bildirim, cardio timer, tamamlanma % düzeltmesi
- `lib/screens/active_workout_screen.dart` — UI yeniden düzenleme, cardio timer UI
- `lib/screens/exercise_info_screen.dart` — Chart kaldırıldı, Repeats Required düzeltildi
- `lib/screens/home_screen.dart` — Muscle Groups sıralama değişikliği
- `lib/screens/settings_screen.dart` — Depolama izni + timestamp backup
