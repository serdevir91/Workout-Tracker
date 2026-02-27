# Workout Tracker — Optimizasyon Planı

> Oluşturulma: 27 Şubat 2026
> Durum: Bekleniyor (uygulama beklemede)

---

## Özet

Tüm `lib/` altındaki 23 dosya tarandı. **5 kritik**, **14 yüksek**, **12 orta**, **8 düşük** seviyeli sorun tespit edildi. En büyük sorun: **Timer her saniye `notifyListeners()` çağırarak tüm widget ağacını baştan rebuild ettiriyor.**

| Seviye | Sayı | Ana Tema |
|--------|------|----------|
| 🔴 Kritik | 5 | Timer tüm ekranı rebuild eder, 21 DB sorgusu, dev provider, 1400+ satırlık dosya |
| 🟠 Yüksek | 14 | N+1 query, index eksikliği, gereksiz watch, cardio algılama build'de, JSON yeniden yükleme |
| 🟡 Orta | 12 | shouldRepaint=true, sınırsız cache, const eksikliği, bildirim overhead, ölü kod |
| ⚪ Düşük | 8 | Kullanılmayan import/değişken, controller temizliği, eksik key |

---

## 🔴 KRİTİK — Öncelik 1

### K1. Timer Her Saniye Tüm Widget Ağacını Rebuild Ediyor
- **Dosya:** `workout_provider.dart` L560–580
- **Sorun:** `Timer.periodic(1s)` → `notifyListeners()` → `context.watch<WorkoutProvider>()` kullanan **tüm ekranlar** (HomeScreen 1408 satır dahil) her saniye baştan build ediliyor
- **Etki:** ~60 tam ekran rebuild/dakika, FPS düşüşü, pil tüketimi
- **Çözüm:**
  1. Timer süresini ayrı bir `ValueNotifier<int>` olarak çıkar
  2. Sadece timer gösteren widget'lar `ValueListenableBuilder` ile dinlesin
  3. Ana provider'dan timer tick'ini kaldır — sadece veri değişikliklerinde `notifyListeners()` çağır

### K2. Haftalık Grafikler İçin 21 DB Sorgusu
- **Dosya:** `database_helper.dart` L508–577
- **Sorun:** `getWeeklyVolumeStats()`, `getWeeklyRepsStats()`, `getWeeklySetsStats()` her biri 7 gün için ayrı sorgu çalıştırıyor = 3×7 = **21 sorgu**
- **Etki:** Home ekranı açılışında ve tab değişiminde ciddi gecikme
- **Çözüm:**
  1. Tek SQL sorgusu: `SELECT date(start_time), SUM(volume), SUM(reps), SUM(sets) FROM ... WHERE start_time >= ? GROUP BY date(start_time)`
  2. Dart tarafında 7 günlük array'e dağıt
  3. 21 sorgu → 1 sorgu

### K3. Tek Dev Provider (God Class)
- **Dosya:** `workout_provider.dart` (731 satır)
- **Sorun:** Workout listesi, aktif antrenman, timer, rest timer, cardio timer, draft input, plan, off day, istatistik — hepsi tek `ChangeNotifier`'da. Her `notifyListeners()` hepsini tetikliyor
- **Etki:** Timer tick → HomeScreen grafikleri rebuild, Library ekranı rebuild, Stats rebuild
- **Çözüm:** Provider'ı bölmek:
  - `WorkoutTimerProvider` — sadece elapsed seconds, timer state
  - `ActiveWorkoutProvider` — aktif antrenman, egzersizler, setler
  - `WorkoutHistoryProvider` — geçmiş antrenmanlar, istatistikler
  - `WorkoutPlanProvider` — planlar, off days

### K4. HomeScreen 1408 Satır — Monolitik Dosya
- **Dosya:** `home_screen.dart` (1408 satır)
- **Sorun:** Dashboard, takvim, antrenman geçmişi kartları, haftalık grafik, donut chart, kalori chart, bottom nav, 2 CustomPainter, period seçici, next training kartları — hepsi tek dosyada
- **Etki:** Okunabilirlik düşük, her değişiklikte tüm dosya etkileniyor, widget extraction imkansız
- **Çözüm:** 7 ayrı dosyaya böl:
  - `widgets/home_dashboard.dart`
  - `widgets/weekly_chart.dart`
  - `widgets/muscle_group_chart.dart`
  - `widgets/calories_chart.dart`
  - `widgets/calendar_widget.dart`
  - `widgets/chart_painters.dart`
  - `widgets/next_training_cards.dart`

### K5. HomeScreen build() İçinde Chart Yenileme Kontrolü
- **Dosya:** `home_screen.dart` L133–142
- **Sorun:** `build()` içinde `provider.workouts.length` karşılaştırması var. Timer her saniye `notifyListeners()` çağırdığı için bu kontrol saniyede 1 kez çalışıyor — `addPostFrameCallback` çağrısı dahil
- **Çözüm:** `build()` yerine provider'a listener ekle veya `didChangeDependencies` kullan

---

## 🟠 YÜKSEK — Öncelik 2

### Y1. context.watch Aynı build'de Birden Fazla Kez
- **Dosya:** `home_screen.dart` L133 ve L144
- **Sorun:** Aynı `build()` içinde `context.watch<WorkoutProvider>()` iki kez çağrılıyor
- **Çözüm:** Tek kez çağır, değişkene ata, child method'lara parametre olarak geçir

### Y2. Consumer İçinde Tekrar context.watch
- **Dosya:** `home_screen.dart` L800–801 (`_buildNextTrainingCards`)
- **Sorun:** Zaten `Consumer2` içindeyken `context.watch<WorkoutProvider>()` tekrar çağrılıyor
- **Çözüm:** Provider'ı parametre olarak al

### Y3. ExerciseInfoScreen'de Tüm Ekranı Saran Consumer
- **Dosya:** `exercise_info_screen.dart` L160
- **Sorun:** `Consumer<WorkoutProvider>` tüm ekranı sarıyor. Timer tick'i tüm ekranı rebuild ediyor
- **Çözüm:** `Selector` kullan, sadece bağımlı alanları (setler, rest timer) dinle

### Y4. ExerciseInfoScreen'de İç İçe Consumer
- **Dosya:** `exercise_info_screen.dart` L532
- **Sorun:** Zaten Consumer içindeyken `_buildHistorySection` içinde tekrar `Consumer` var
- **Çözüm:** Kaldır, provider'ı parametre olarak geçir

### Y5. Cardio Algılama Her Build'de Tekrarlanıyor
- **Dosya:** `active_workout_screen.dart` L227–232
- **Sorun:** Her egzersiz kartı için 18+ `contains()` String kontrolü, her saniye (timer rebuild) tekrarlanıyor. 7 egzersiz = 126 contains/saniye
- **Çözüm:** `ActiveExercise` modeline `bool isCardio` alanı ekle, egzersiz eklendiğinde bir kez hesapla

### Y6. ExrxUrlMatcher.findExercise — onTap'te Senkron Arama
- **Dosya:** `active_workout_screen.dart` L262
- **Sorun:** Egzersiz adına tıklayınca ~1000+ JSON kaydında lineer arama — UI thread'i blokluyor
- **Çözüm:** Önceden Map'e index'le veya loading indicator göster

### Y7. buildMuscleGroupMap() Her Çağrıda Yeniden Oluşturuyor
- **Dosya:** `exrx_url_matcher.dart` L127–135
- **Sorun:** ~1000 kayıttan Map oluşturuyor, her period filtre değişiminde tekrar
- **Çözüm:** Statik cache'le, ilk çağrıdan sonra aynı Map'i dön

### Y8. N+1 Sorgu — loadWorkouts() Kurtarma
- **Dosya:** `workout_provider.dart` L164–186
- **Sorun:** Her egzersiz için `getSetsByExerciseId` + `getLastExerciseRecord` = 2 sorgu × N egzersiz
- **Çözüm:** JOIN ile tek sorguda çek

### Y9. N+1 Sorgu — getExerciseHistory()
- **Dosya:** `database_helper.dart` L651–681
- **Sorun:** 20 kayıt × ayrı set sorgusu = 20 ekstra sorgu
- **Çözüm:** JOIN ile tek sorgu, Dart'ta grupla

### Y10. N+1 Sorgu — getAllWorkoutTemplates()
- **Dosya:** `database_helper.dart` L688–703
- **Sorun:** Her template için ayrı exercise sorgusu
- **Çözüm:** JOIN ile tek sorgu

### Y11. N+1 Sorgu — loadWorkoutDetail()
- **Dosya:** `workout_provider.dart` L555–565
- **Sorun:** Her egzersiz için ayrı set sorgusu
- **Çözüm:** Batch JOIN sorgusu

### Y12. DB Index Eksikliği
- **Dosya:** `database_helper.dart` L71–97 (`_onCreate`)
- **Sorun:** `exercises.workout_id`, `exercise_sets.exercise_id`, `exercises.name`, `workouts.start_time` — her JOIN/WHERE'de kullanılan sütunlara index yok
- **Çözüm:** Migration'da `CREATE INDEX` ekle (DB version 9'a yükselt)

### Y13. Exercise JSON Her Library Açılışında Yeniden Yükleniyor
- **Dosya:** `exercise_library_screen.dart` L55–77
- **Sorun:** `rootBundle.loadString` + `json.decode` ~1000 kayıt, her tab değişiminde
- **Çözüm:** `ExrxUrlMatcher._exercises` cache'ini kullan (zaten cache var, library da onu kullansın)

### Y14. Tamamlanma Yüzdesi 3 Yerde Tekrarlanıyor
- **Dosyalar:** `workout_provider.dart` L252–264, L294–306; `active_workout_screen.dart` L79–87
- **Sorun:** Aynı hesaplama 3 kez yazılmış
- **Çözüm:** Provider'da `double get completionPercentage` getter yap, tek kaynak

---

## 🟡 ORTA — Öncelik 3

### O1. CustomPainter shouldRepaint Daima true
- **Dosya:** `home_screen.dart` L1302, L1387
- **Sorun:** `_DonutPainter` ve `_CaloriesChartPainter` veri değişmese bile repaint ediliyor
- **Çözüm:** Önceki delegate verisiyle karşılaştır

### O2. Missing `const` Keyword'ler
- **Dosyalar:** `active_workout_screen.dart` L375–376, `home_screen.dart` çeşitli yerler
- **Sorun:** `Text`, `TextStyle`, `SizedBox` gibi widget'larda `const` eksik = gereksiz obje allocation
- **Çözüm:** Mümkün olan her yere `const` ekle

### O3. GIF Cache Sınırsız Büyüyor
- **Dosya:** `exercise_thumbnail.dart` L18
- **Sorun:** Statik `Map<String, String?>` hiç silme yapmıyor, 1000+ kayıt birikebilir
- **Çözüm:** LRU cache (max 200 kayıt)

### O4. Rest Timer Ayrı notifyListeners() Çağrısı
- **Dosya:** `workout_provider.dart` L590–600
- **Sorun:** Workout timer + rest timer aktifken saniyede 2× notifyListeners
- **Çözüm:** Rest timer'ı ana timer tick'ine birleştir

### O5. Notification Details Her Saniye Yeniden Oluşturuluyor
- **Dosya:** `notification_service.dart` L57–75
- **Sorun:** `AndroidNotificationDetails` her `showWorkoutNotification()` çağrısında yeni obje
- **Çözüm:** Sabit kısmı static const olarak cache'le

### O6. Network GIF'leri Tam Çözünürlükte Yükleniyor
- **Dosya:** `exercise_library_screen.dart` L301–315
- **Sorun:** GIF thumbnail'leri cacheWidth/cacheHeight olmadan yükleniyor = fazla bellek
- **Çözüm:** `cacheWidth: (size * devicePixelRatio).toInt()` ekle

### O7. Ölü Kod — image_mapper.dart (Tüm Dosya)
- **Dosya:** `image_mapper.dart` (65 satır)
- **Sorun:** Hiçbir yerden import edilmiyor
- **Çözüm:** Sil

### O8. Ölü Kod — translations.dart (Tüm Dosya)
- **Dosya:** `translations.dart` (125 satır)
- **Sorun:** `tr()` extension ve `Translations.get()` hiçbir ekrandan çağrılmıyor
- **Çözüm:** Sil veya entegre et

### O9. Ölü Kod — commonExercises Listesi
- **Dosya:** `workout_models.dart` L163–184
- **Sorun:** `commonExercises` tanımlı ama hiç kullanılmıyor
- **Çözüm:** Sil

### O10. GIF Yüklemede Fade-in / Disk Cache Yok
- **Dosya:** `exercise_info_screen.dart` L351–385
- **Sorun:** 280px GIF `Image.network` ile yükleniyor, cache ve geçiş animasyonu yok
- **Çözüm:** `CachedNetworkImage` paketi kullan

### O11. Missing itemExtent on ListView
- **Dosyalar:** `active_workout_screen.dart` L175, `exercise_library_screen.dart` L438
- **Sorun:** Performans kaybı, özellikle 1000+ item'lık kütüphanede
- **Çözüm:** `itemExtent` belirle

### O12. ListView Item'larında Key Eksik
- **Dosya:** `home_screen.dart` ~L287, ~L310
- **Sorun:** `.map()` ile üretilen list item'larında `ValueKey` yok
- **Çözüm:** `key: ValueKey(workout.id)` ekle

---

## ⚪ DÜŞÜK — Öncelik 4

| # | Dosya | Sorun | Çözüm |
|---|-------|-------|-------|
| D1 | `workout_provider.dart` L51 | `_activeWorkoutTargetSets` unused field | Sil (ve tüm assign'ları) |
| D2 | `workout_detail_screen.dart` L5 | Kullanılmayan import `image_mapper.dart` | Sil |
| D3 | `formatters.dart` L33–42 | `calculateTotalVolume` hiç çağrılmıyor | Sil |
| D4 | `notification_service.dart` L1 | Kullanılmayan `import 'dart:async'` | Sil |
| D5 | `active_workout_screen.dart` L22–23 | Controller map'leri silinen egzersizler için temizlenmiyor | deleteExercise'de temizle |
| D6 | `exercise_thumbnail.dart` | `didUpdateWidget` eksik | Ekle |
| D7 | `database_helper.dart` L291 | Manuel CASCADE delete (PRAGMA foreign_keys=ON verilmemiş) | PRAGMA ekle |
| D8 | Çeşitli | Unused local variables (minor) | Kaldır |

---

## Uygulama Sırası (Önerilen)

Aşağıdaki sırada uygulanması önerilir — her aşama bağımsız test edilebilir:

### Aşama 1 — Timer İzolasyonu (En Büyük Etki)
> K1 + K3 (kısmi) + Y3 + Y4 + O4
- Timer'ı ayrı `ValueNotifier<int>` olarak çıkar
- `notifyListeners()` sadece veri değişikliğinde çağrılsın
- Consumer'ları `Selector`/`ValueListenableBuilder` ile değiştir
- Rest timer'ı ana tick'e birleştir

### Aşama 2 — DB Optimizasyonu
> K2 + Y8–Y11 + Y12
- Haftalık stats'ı 1 sorguya indir (21 → 1)
- N+1 sorguları JOIN ile birleştir
- Index'leri ekle (DB v9 migration)

### Aşama 3 — Build Method Temizliği
> K5 + Y1 + Y2 + Y5 + Y6 + Y7 + Y13 + Y14
- build() içinden chart kontrolünü çıkar
- context.watch tekrarlarını kaldır
- Cardio algılamayı model'e taşı
- JSON cache'i paylaş
- Tamamlanma % getter'a taşı

### Aşama 4 — Widget Extraction
> K4 + ayrıca exercise_info, active_workout, database_helper, provider
- HomeScreen'i 7 dosyaya böl
- Diğer büyük dosyaları böl

### Aşama 5 — Ölü Kod Temizliği
> O7 + O8 + O9 + D1–D4
- Kullanılmayan dosyaları sil
- Kullanılmayan import/değişkenleri temizle

### Aşama 6 — Polish
> O1 + O2 + O3 + O5 + O6 + O10 + O11 + O12 + D5–D8
- shouldRepaint düzelt
- const ekle
- Cache limitleri
- Network image optimizasyonu

---

## Beklenen Sonuçlar

| Metrik | Şu An | Hedef |
|--------|-------|-------|
| build() çağrısı/dakika (HomeScreen) | ~60 (timer) | ~2 (veri değişikliğinde) |
| DB sorgusu (haftalık chart) | 21 | 1 |
| DB sorgusu (exercise history) | 20+ | 1 |
| Büyük dosya sayısı (>500 satır) | 6 | 0 |
| Ölü kod dosyası | 2 | 0 |
| Kullanılmayan değişken/import | 8+ | 0 |
