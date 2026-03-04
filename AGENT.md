# Workout Tracker — Proje Rehberi (Agent Reference)

> Bu dosya AI agent'ların projeyi hızlıca anlaması için oluşturulmuştur.
> Son güncelleme: 4 Mart 2026

---

## Genel Bakış
Flutter ile yazılmış bir antrenman takip uygulaması. Android + Windows + Web desteği var.
State management: **Provider**. Veritabanı: **SQLite (sqflite)** şema v13. ORM yok, ham SQL kullanılıyor.
Egzersiz veritabanı: **free-exercise-db** (873 egzersiz, public domain / Unlicense).
Görsel kaynağı: GitHub CDN üzerinden JPG resimler, otomatik GIF-benzeri animasyonlu gösterim.
Tema: Koyu glassmorphism UI. Renk paleti: Mor `#6C63FF`, Mint yeşil `#00D4AA`, Hata kırmızı `#FF6B6B`, Arka plan `#0F0F23`.

---

## Klasör Yapısı

```
Workout-Tracker/
├── lib/
│   ├── main.dart                          # Uygulama girişi, tema, MultiProvider setup (~170 satır)
│   ├── db/
│   │   └── database_helper.dart           # Singleton SQLite helper, 7 tablo, v8 şema (~777 satır)
│   ├── l10n/
│   │   └── translations.dart              # EN/TR/ES çeviri map'leri
│   ├── models/
│   │   ├── workout_models.dart            # Workout, Exercise, ExerciseSet modelleri (~186 satır)
│   │   └── workout_plan_models.dart       # WorkoutPlan, PlanExercise, 5 default plan (~202 satır)
│   ├── services/
│   │   └── notification_service.dart      # Singleton bildirim servisi (workout notifications) (~85 satır)
│   ├── providers/
│   │   ├── workout_provider.dart          # Tüm workout mantığı, timer, bildirim, cardio, CRUD (~697 satır)
│   │   └── settings_provider.dart         # Tema, dil, ölçü birimi, profil (~132 satır)
│   ├── screens/
│   │   ├── home_screen.dart               # Dashboard, takvim, haftalık grafik, kas grubu (~1390 satır)
│   │   ├── active_workout_screen.dart     # Aktif antrenman UI, set ekleme, cardio timer (~707 satır)
│   │   ├── exercise_info_screen.dart      # Egzersiz detay, GIF, set girişi, geçmiş (~827 satır)
│   │   ├── exercise_library_screen.dart   # Egzersiz kütüphanesi, arama, filtreleme (~677 satır)
│   │   ├── settings_screen.dart           # Ayarlar, profil, backup/restore, izin yönetimi (~370 satır)
│   │   ├── stats_screen.dart              # İstatistikler genel bakış (~238 satır)
│   │   ├── workout_detail_screen.dart     # Tamamlanmış antrenman detayı
│   │   ├── workout_summary_screen.dart    # Antrenman bitişi özet ekranı
│   │   ├── create_routine_screen.dart     # Plan oluşturma/düzenleme
│   │   ├── plans_screen.dart              # Plan listesi
│   │   └── workout_schedule_screen.dart   # Haftalık program
│   ├── utils/
│   │   ├── formatters.dart                # Süre, tarih, sayı formatlama
│   │   └── exercise_db.dart               # free-exercise-db utility: findExercise, findMuscleGroup, imageUrl vb.
│   └── widgets/
│       └── exercise_thumbnail.dart        # Egzersiz küçük resim widget'ı (LRU cache)
├── assets/
│   ├── data/
│   │   └── free_exercises.json            # 873 egzersiz (free-exercise-db, Unlicense)
│   ├── images/                            # Uygulama görselleri
│   └── screenshots/                       # Mağaza ekran görüntüleri
├── android/
│   └── app/src/main/AndroidManifest.xml   # INTERNET + storage + notification + foreground izinleri
├── windows/                               # Windows masaüstü desteği
├── web/                                   # Web desteği
├── test/
│   └── widget_test.dart                   # Test dosyası
├── pubspec.yaml                           # Bağımlılıklar, asset tanımları
├── TASKS.md                               # Görev listesi (aktif)
├── AGENT.md                               # Bu dosya
└── .github/
    └── copilot-instructions.md            # Proje özel Copilot talimatları
```

---

## Veritabanı Şeması (v13)

| Tablo | Sütunlar | İlişki |
|-------|----------|--------|
| `workouts` | `id` PK, `name`, `start_time`, `end_time`, `total_duration`, `calories`, `completion_percentage` | — |
| `exercises` | `id` PK, `workout_id` FK, `name`, `start_time`, `end_time`, `duration`, `exercise_order` | → workouts (CASCADE) |
| `exercise_sets` | `id` PK, `exercise_id` FK, `set_number`, `weight`, `reps`, `completed` | → exercises (CASCADE) |
| `user_settings` | `id` PK (=1), `theme`, `language`, `unit`, `height`, `weight`, `last_weight_update`, schedule fields | Singleton satır |
| `off_days` | `date` PK | — |
| `workout_templates` | `id` PK, `day_number`, `name`, `target_muscles` | — |
| `template_exercises` | `id` PK, `template_id` FK, `name`, `sets`, `reps`, `weight`, `duration_minutes`, `rest_seconds` | → workout_templates (CASCADE) |

---

## Önemli Modeller

### `Workout` → `workout_models.dart`
- `id`, `name`, `startTime`, `endTime`, `totalDuration` (saniye), `calories`, `completionPercentage`

### `Exercise` → `workout_models.dart`
- `id`, `workoutId`, `name`, `startTime`, `endTime`, `duration` (saniye), `exerciseOrder`

### `ExerciseSet` → `workout_models.dart`
- `id`, `exerciseId`, `setNumber`, `weight` (kg), `reps`, `completed` (bool)
- **Cardio set'lerde:** `weight = 0`, `reps = dakika` (geçici çözüm)

### `WorkoutPlan` → `workout_plan_models.dart`
- `id`, `dayNumber`, `name`, `targetMuscles`, `exercises` (List\<PlanExercise\>)

### `PlanExercise` → `workout_plan_models.dart`
- `id`, `templateId`, `name`, `sets`, `reps`, `weight`, `durationMinutes?`, `restSeconds`

---

## State Management

### WorkoutProvider (`workout_provider.dart`)
Tüm antrenman mantığının merkezi. `ChangeNotifier` + `WidgetsBindingObserver`.

**Aktif antrenman state'i:**
- `_activeWorkout` — mevcut Workout nesnesi
- `_activeExercises` — `List<ActiveExercise>` (exercise + sets + hedefler)
- `_activeWorkoutTargetSets` — plan hedef set sayısı (free workout için 0)
- `_workoutElapsedSeconds` — toplam antrenman süresi
- `_exerciseElapsedSeconds` — egzersiz bazlı süre map'i
- `_timer` — `Timer.periodic(1s)` her saniye tick
- `_isTimerRunning` — pause/resume durumu
- `_restTimerSeconds` / `_restTimer` — dinlenme sayacı
- `_draftWeights` / `_draftReps` — geçici input değerleri
- `_notificationService` — bildirim servisi referansı
- `_lastSetInfo` — son set bilgisi (bildirim içeriği)
- `_activeCardioTimerIds` — aktif cardio timer'ları takip eden Set<int>
- `_cardioElapsedSeconds` — egzersiz bazlı cardio süre map'i

**Önemli metodlar:**
- `startWorkout(name)` / `startWorkoutFromPlan(plan)` — yeni antrenman başlat
- `finishWorkout()` — tamamlanma % hesapla, DB'ye kaydet
- `cancelWorkout()` — antrenmanı iptal et
- `addExercise(name)` / `deleteExercise(id)` — egzersiz ekle/sil
- `addSet(exerciseId, weight, reps)` — set ekle + rest timer başlat
- `updateSet()` / `deleteSet()` — set güncelle/sil
- `pauseTimer()` / `resumeTimer()` — timer kontrol
- `startRestTimer(seconds)` / `stopRestTimer()` — dinlenme sayacı
- `startCardioTimer(exerciseId)` / `stopCardioTimer(exerciseId)` — cardio timer kontrol
- `isCardioTimerActive(exerciseId)` — cardio timer durumu
- `didChangeAppLifecycleState()` — arka plan süre telafisi
- `getExerciseHistory(name)` — egzersiz geçmişi
- `loadWorkoutDetail(id)` — antrenman detayı
- `getWeeklyVolumeStats()` — haftalık istatistikler

### SettingsProvider (`settings_provider.dart`)
- Tema, dil, birim, profil ayarları
- Her değişiklik anında DB'ye yazılır (`_saveToDb`)

---

## Ekran Haritası

```
HomeScreen (dashboard)
├── Calendar + günlük antrenman listesi
├── Next Training kartları
├── Muscle Group Distribution donut chart  ← Weekly Overview üstüne taşındı
├── Weekly Overview bar chart (Volume/Reps/Sets)
├── Calories burned chart
│
├──→ ActiveWorkoutScreen (aktif antrenman)
│   ├── AppBar: Workout adı + Timer (play/pause)
│   ├── Progress bar (completedSets / totalPlannedSets)
│   ├── Rest timer banner
│   ├── Egzersiz kartları listesi (set tablosu + input / cardio timer)
│   └── Bottom bar: [Cancel (kırmızı)] [Add Exercise (mor, expanded)] [Finish (yeşil)]
│   │
│   ├──→ ExerciseInfoScreen (egzersiz detay, set gir)
│   └──→ ExerciseLibraryScreen (egzersiz seç, pickMode)
│
├──→ WorkoutSummaryScreen (antrenman özeti)
├──→ WorkoutDetailScreen (geçmiş antrenman detayı)
├──→ PlansScreen → CreateRoutineScreen (plan yönetimi)
├──→ WorkoutScheduleScreen (haftalık program)
├──→ StatsScreen (istatistikler)
└──→ SettingsScreen (ayarlar, profile, backup/restore)
```

---

## Bağımlılıklar (pubspec.yaml)

| Paket | Versiyon | Amaç |
|-------|----------|------|
| `sqflite` | ^2.4.2 | SQLite veritabanı |
| `sqflite_common_ffi` | ^2.4.0+2 | Desktop SQLite |
| `sqflite_common_ffi_web` | ^1.1.1 | Web SQLite |
| `sqlite3_flutter_libs` | ^0.6.0+eol | Native SQLite kütüphaneler |
| `path_provider` | ^2.1.5 | Dosya sistemi yolları |
| `path` | ^1.9.1 | Path işlemleri |
| `provider` | ^6.1.5+1 | State management |
| `intl` | ^0.20.2 | Tarih/sayı formatlama |
| `table_calendar` | ^3.2.0 | Takvim widget |
| `file_picker` | ^8.1.7 | Dosya/klasör seçici (backup) |
| `meta` | ^1.11.0 | Annotation'lar |
| `cupertino_icons` | ^1.0.8 | iOS ikonları |
| `permission_handler` | ^11.3.1 | Runtime izin yönetimi (storage, notification) |
| `flutter_local_notifications` | ^18.0.1 | Persistent workout bildirimleri |

---

## Android İzinleri

| İzin | Durum |
|------|-------|
| `INTERNET` | ✅ Var |
| `POST_NOTIFICATIONS` | ✅ Eklendi |
| `FOREGROUND_SERVICE` | ✅ Eklendi |
| `READ_EXTERNAL_STORAGE` | ✅ Eklendi |
| `WRITE_EXTERNAL_STORAGE` | ✅ Eklendi |
| `MANAGE_EXTERNAL_STORAGE` | ✅ Eklendi |
| `VIBRATE` | ✅ Eklendi |

---

## Cardio Algılama (Genişletildi)

`active_workout_screen.dart` — genişletilmiş cardio keyword listesi:
```dart
// EN keywords: bike, run, treadmill, cardio, cycling, rowing, elliptical, 
//              jump rope, swimming, stair, walk
// TR keywords: bisiklet, koşu, kürek, yüzme, merdiven, yürüyüş, ip atlama
```
Cardio set'lerde: `weight = 0`, `reps = dakika olarak süre`.
Cardio UI: Büyük timer gösterimi + Start/Stop butonu + "Save (X min)" butonu.

---

## Bilinen Sorunlar / Teknik Borç
1. ~~**Cardio algılama** string match ile yapılıyor — kırılgan~~ → Genişletildi ama hâlâ string match
2. **ExerciseSet** modelinde `isCardio` / `duration` alanı yok (hâlâ reps=dakika workaround)
3. ~~**Timer** foreground service olmadan arka planda duruyor~~ → Notification eklendi, wall-clock compensation mevcut
4. ~~**Tamamlanma yüzdesi** farklı formüller~~ → Düzeltildi, aynı formül kullanılıyor
5. ~~**Chart butonu** boş onTap~~ → Kaldırıldı
6. ~~**Library butonu** gereksiz tekrar~~ → Kaldırıldı
7. ~~**Backup** PathAccessException~~ → permission_handler ile çözüldü
8. Tüm grafikler `CustomPainter` ile çiziliyor — charting kütüphanesi yok
9. **Foreground service** yok — agresif OEM'lerde (Xiaomi, Samsung) arka plan timer durabilir
10. ~~Cardio geçmişi exercise_info & summary ekranlarında hâlâ "X kg x Y reps" formatında~~ → Düzeltildi
11. ~~**ExRx.net lisanslama sorunu**~~ → free-exercise-db (Unlicense) ile değiştirildi
12. ~~**Exercise timer** sadece son egzersize yazıyordu~~ → v3.0.1'de aktif görüntülenen egzersize yazılıyor
13. ~~**finishWorkout** sadece son egzersizi kapatıyordu~~ → v3.0.1'de tüm açık egzersizler kapatılıyor
14. ~~**Kas grubu kategorileri** çok genel (Arms, Legs)~~ → v3.0.1'de Biceps/Triceps, Quadriceps/Hamstrings, Lower Back ayrıldı
15. ~~**Muscle group matching** custom egzersiz isimlerinde başarısız~~ → v3.0.1'de 60+ override + fuzzy matching + cache

---

## Build & Çalıştırma

```bash
# Geliştirme
flutter pub get
flutter run -d android          # Android
flutter run -d windows          # Windows
flutter run -d chrome           # Web

# Analiz & Test
flutter analyze
flutter test

# Release
flutter build apk --release
flutter build windows --release
```

---

## Kodlama Kuralları
- Tüm fonksiyonlara tip tanımlama (return type + parametre tipleri)
- `const` constructor kullan (performans)
- Provider pattern: `context.read<T>()` (tek okuma), `context.watch<T>()` (dinleme)
- DB değişikliği → `database_helper.dart`'ta version artır + `_onUpgrade` migration ekle
- Model değişikliği → `toMap()` / `fromMap()` güncelle
- Yeni ekran → `screens/` klasörüne ekle, `Navigator.push()` ile navigasyon
- Çeviri → `translations.dart`'a EN/TR/ES key ekle
