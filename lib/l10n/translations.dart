// Centralized translation system for the Workout Tracker app.
// Supports: English (en), Türkçe (tr), Español (es), Deutsch (de), Français (fr)
//
// Usage:
//   final t = Translations.of(context);
//   Text(t.get('home'))
//
// Or with static access:
//   Translations.translate('home', 'tr')

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class Translations {
  final String locale;

  Translations(this.locale);

  /// Get translation from current context's language setting.
  static Translations of(BuildContext context) {
    final lang = context.read<SettingsProvider>().language;
    return Translations(lang);
  }

  /// Static translate helper.
  static String translate(String key, String locale) {
    return _translations[locale]?[key] ?? _translations['en']?[key] ?? key;
  }

  /// Get translated string by key.
  String get(String key) {
    return _translations[locale]?[key] ?? _translations['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // ═══════════════════════════════════════════════════
    //  ENGLISH
    // ═══════════════════════════════════════════════════
    'en': {
      // Navigation
      'home': 'Home',
      'workouts': 'Workouts',
      'library': 'Library',
      'stats': 'Stats',

      // Settings
      'settings': 'Settings',
      'profile': 'Profile',
      'my_body_stats': 'My Body Stats',
      'preferences': 'Preferences',
      'theme': 'Theme',
      'language': 'Language',
      'measurement_system': 'Measurement System',
      'metric': 'Metric',
      'imperial': 'Imperial',
      'data_management': 'Data Management',
      'backup_database': 'Backup Database',
      'backup_desc': 'Save your data to a file',
      'restore_database': 'Restore Database',
      'restore_desc': 'Load data from a backup file',
      'restore_confirm':
          'This will overwrite all current data with the backup. Are you sure?',
      'restore_title': 'Restore Backup',
      'cancel': 'Cancel',
      'save': 'Save',
      'restore': 'Restore',
      'edit_profile': 'Edit Profile',
      'edit_body_stats': 'Edit Body Stats',
      'height': 'Height',
      'weight': 'Weight',
      'system_theme': 'System',
      'dark_theme': 'Dark',
      'light_theme': 'Light',
      'english': 'English',
      'turkish': 'Türkçe',
      'spanish': 'Español',
      'german': 'Deutsch',
      'french': 'Français',

      // Body stats
      'body_measurements': 'Body Measurements',
      'arm_circumference': 'Arm',
      'waist_circumference': 'Waist',
      'shoulder_width': 'Shoulders',
      'chest_circumference': 'Chest',
      'hip_circumference': 'Hips',
      'thigh_circumference': 'Thigh',
      'calf_circumference': 'Calf',
      'neck_circumference': 'Neck',
      'forearm_circumference': 'Forearm',
      'body_progress': 'Body Progress',
      'update_measurements': 'Update Measurements',
      'no_measurements_yet':
          'No measurements recorded yet.\nTap the button to add your first measurement.',
      'measurement_saved': 'Measurements saved!',
      'select_measurement': 'Select Measurement',

      // Home
      'next_training': 'Next Training',
      'weekly_overview': 'Weekly Overview',
      'volume': 'Volume',
      'reps': 'Reps',
      'sets': 'Sets',
      'muscle_groups': 'Muscle Groups',
      'calories_burned': 'Calories Burned (kcal)',
      'more': 'More',
      'last': 'Last',
      'week': 'Week',
      'month': 'Month',
      'all_time': 'All Time',
      'no_routines': "No routines created. Tap 'Workouts' tab to create.",
      'workout_in_progress': 'Workout in progress',
      'scheduled_routines': 'Scheduled Routines',
      'completed_workouts': 'Completed Workouts',
      'rest_day': 'Rest Day 😌',
      'start_free_workout': 'Start Free Workout Now',
      'auto_scheduled': 'Auto Scheduled',
      'every': 'Every',
      'no_workout_data_yet': 'No workout data yet',
      'no_calorie_data_yet': 'No calorie data yet',
      'sets_label': 'sets',

      // Active Workout
      'no_active_workout': 'No active workout',
      'add_exercise': 'Add Exercise',
      'finish': 'Finish',
      'rest_timer': 'Rest Timer',
      'exercise': 'Exercise',

      // Workout History
      'add_workout': 'Add Workout',
      'my_workout': 'My Workout',
      'no_routines_created':
          'No routines created yet. Create one to get started!',
      'all_past_workouts': 'All Past Workouts',
      'no_workouts_found': 'No workouts found',
      'delete': 'Delete',
      'delete_workout_confirm': 'Delete this workout?',
      'workout_completed': 'Workout Completed!',

      // Stats
      'total_workouts': 'Total Workouts',
      'total_volume': 'Total Volume',
      'total_sets': 'Total Sets',
      'total_duration': 'Total Duration',

      // Units
      'kg': 'kg',
      'lbs': 'lbs',
      'cm': 'cm',
      'in': 'in',
      'ft': 'ft',

      // Misc
      'no_data': 'No data',
      'exercises_label': 'exercises',
      'storage_permission_required':
          'Storage permission is required for backup. Please grant it in Settings.',
      'open_settings': 'Open Settings',
      'backup_saved': 'Backup saved successfully',
      'backup_failed': 'Backup failed',
      'restore_success': 'Restore successful! Data reloaded.',
      'restore_failed': 'Restore failed',
      'file_not_found': 'Selected file not found.',
      'workout_details': 'Workout Details',

      // Rest Timer Notifications
      'rest_started': 'Rest Time',
      'rest_finished': 'Rest Finished!',
      'rest_finished_body': 'Time for your next set! 💪',
      'resting': 'Resting',

      // Color Palette
      'color_palette': 'Color Palette',
      'color_palette_desc': 'Customize app accent colors',
      'palette_default': 'Default Purple',
      'palette_ocean': 'Ocean Blue',
      'palette_sunset': 'Sunset Orange',
      'palette_forest': 'Forest Green',
      'palette_rose': 'Rose Pink',
      'palette_crimson': 'Crimson Red',
      'appearance': 'Appearance',
      'background_mode': 'Background',
      'bg_default': 'Default',
      'pure_black': 'Pure Black (AMOLED)',

      // Days
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',

      // New features
      'alternative_exercise': 'Alternative Exercise',
      'swap_exercise': 'Swap Exercise',
      'same_muscle_group': 'Same muscle group alternatives',
      'add_to_workout': 'Add to Workout',
      'select_workout': 'Select Workout',
      'manual_duration': 'Manual Duration',
      'enter_duration_min': 'Enter duration (min)',
      'first_day_of_week': 'First Day of Week',
      'avg_volume_per_workout': 'Avg volume per workout',
      'avg_duration_per_workout': 'Avg duration per workout',
      'avg_sets_per_workout': 'Avg sets per workout',
      'best_workout': 'Best workout',
      'day': 'Day',
    },

    // ═══════════════════════════════════════════════════
    //  TURKISH
    // ═══════════════════════════════════════════════════
    'tr': {
      // Navigation
      'home': 'Ana Sayfa',
      'workouts': 'Antrenmanlar',
      'library': 'Kütüphane',
      'stats': 'İstatistik',

      // Settings
      'settings': 'Ayarlar',
      'profile': 'Profil',
      'my_body_stats': 'Vücut Ölçülerim',
      'preferences': 'Tercihler',
      'theme': 'Tema',
      'language': 'Dil',
      'measurement_system': 'Ölçü Sistemi',
      'metric': 'Metrik',
      'imperial': 'İmparatorluk',
      'data_management': 'Veri Yönetimi',
      'backup_database': 'Veritabanını Yedekle',
      'backup_desc': 'Verilerinizi bir dosyaya kaydedin',
      'restore_database': 'Veritabanını Geri Yükle',
      'restore_desc': 'Yedek dosyasından verileri geri yükleyin',
      'restore_confirm':
          'Bu işlem mevcut tüm verilerin üzerine yazacaktır. Emin misiniz?',
      'restore_title': 'Yedeği Geri Yükle',
      'cancel': 'İptal',
      'save': 'Kaydet',
      'restore': 'Geri Yükle',
      'edit_profile': 'Profili Düzenle',
      'edit_body_stats': 'Vücut Ölçülerini Düzenle',
      'height': 'Boy',
      'weight': 'Kilo',
      'system_theme': 'Sistem',
      'dark_theme': 'Koyu',
      'light_theme': 'Açık',
      'english': 'English',
      'turkish': 'Türkçe',
      'spanish': 'Español',
      'german': 'Deutsch',
      'french': 'Français',

      // Body stats
      'body_measurements': 'Vücut Ölçüleri',
      'arm_circumference': 'Kol',
      'waist_circumference': 'Bel',
      'shoulder_width': 'Omuz',
      'chest_circumference': 'Göğüs',
      'hip_circumference': 'Kalça',
      'thigh_circumference': 'Uyluk',
      'calf_circumference': 'Baldır',
      'neck_circumference': 'Boyun',
      'forearm_circumference': 'Ön Kol',
      'body_progress': 'Vücut İlerlemesi',
      'update_measurements': 'Ölçüleri Güncelle',
      'no_measurements_yet':
          'Henüz ölçüm kaydedilmedi.\nİlk ölçümünüzü eklemek için butona dokunun.',
      'measurement_saved': 'Ölçümler kaydedildi!',
      'select_measurement': 'Ölçüm Seç',

      // Home
      'next_training': 'Sıradaki Antrenman',
      'weekly_overview': 'Haftalık Özet',
      'volume': 'Hacim',
      'reps': 'Tekrar',
      'sets': 'Set',
      'muscle_groups': 'Kas grupları',
      'calories_burned': 'Yakılan kalori (kcal)',
      'more': 'Daha fazla',
      'last': 'Son',
      'week': 'Hafta',
      'month': 'Ay',
      'all_time': 'Tüm zamanlar',
      'no_routines': "Rutin oluşturulmadı. 'Antrenmanlar' sekmesine gidin.",
      'workout_in_progress': 'Antrenman devam ediyor',
      'scheduled_routines': 'Planlı Rutinler',
      'completed_workouts': 'Tamamlanan Antrenmanlar',
      'rest_day': 'Dinlenme Günü 😌',
      'start_free_workout': 'Serbest Antrenman Başlat',
      'auto_scheduled': 'Otomatik Planlı',
      'every': 'Her',
      'no_workout_data_yet': 'Henüz antrenman verisi yok',
      'no_calorie_data_yet': 'Henüz kalori verisi yok',
      'sets_label': 'set',

      // Active Workout
      'no_active_workout': 'Aktif antrenman yok',
      'add_exercise': 'Egzersiz Ekle',
      'finish': 'Bitir',
      'rest_timer': 'Dinlenme Sayacı',
      'exercise': 'Egzersiz',

      // Workout History
      'add_workout': 'Antrenman Ekle',
      'my_workout': 'Antrenmanlarım',
      'no_routines_created':
          'Henüz rutin oluşturulmadı. Başlamak için bir tane oluşturun!',
      'all_past_workouts': 'Tüm Geçmiş Antrenmanlar',
      'no_workouts_found': 'Antrenman bulunamadı',
      'delete': 'Sil',
      'delete_workout_confirm': 'Bu antrenman silinsin mi?',
      'workout_completed': 'Antrenman Tamamlandı!',

      // Stats
      'total_workouts': 'Toplam Antrenman',
      'total_volume': 'Toplam Hacim',
      'total_sets': 'Toplam Set',
      'total_duration': 'Toplam Süre',

      // Units
      'kg': 'kg',
      'lbs': 'lbs',
      'cm': 'cm',
      'in': 'inç',
      'ft': 'ft',

      // Misc
      'no_data': 'Veri yok',
      'exercises_label': 'egzersiz',
      'storage_permission_required':
          'Yedekleme için depolama izni gereklidir. Lütfen Ayarlar\'dan izin verin.',
      'open_settings': 'Ayarları Aç',
      'backup_saved': 'Yedek başarıyla kaydedildi',
      'backup_failed': 'Yedekleme başarısız oldu',
      'restore_success': 'Geri yükleme başarılı! Veriler yeniden yüklendi.',
      'restore_failed': 'Geri yükleme başarısız oldu',
      'file_not_found': 'Seçilen dosya bulunamadı.',
      'workout_details': 'Antrenman Detayları',

      // Rest Timer Notifications
      'rest_started': 'Dinlenme Süresi',
      'rest_finished': 'Dinlenme Bitti!',
      'rest_finished_body': 'Sıradaki set için hazır ol! 💪',
      'resting': 'Dinleniyor',

      // Color Palette
      'color_palette': 'Renk Paleti',
      'color_palette_desc': 'Uygulama vurgu renklerini özelleştir',
      'palette_default': 'Varsayılan Mor',
      'palette_ocean': 'Okyanus Mavi',
      'palette_sunset': 'Gün Batımı Turuncu',
      'palette_forest': 'Orman Yeşili',
      'palette_rose': 'Gül Pembesi',
      'palette_crimson': 'Kırmızı',
      'appearance': 'Görünüm',
      'background_mode': 'Arka Plan',
      'bg_default': 'Varsayılan',
      'pure_black': 'Saf Siyah (AMOLED)',

      // Days
      'mon': 'Pzt',
      'tue': 'Sal',
      'wed': 'Çar',
      'thu': 'Per',
      'fri': 'Cum',
      'sat': 'Cmt',
      'sun': 'Paz',
      'monday': 'Pazartesi',
      'tuesday': 'Salı',
      'wednesday': 'Çarşamba',
      'thursday': 'Perşembe',
      'friday': 'Cuma',
      'saturday': 'Cumartesi',
      'sunday': 'Pazar',

      // New features
      'alternative_exercise': 'Alternatif Egzersiz',
      'swap_exercise': 'Egzersiz Değiştir',
      'same_muscle_group': 'Aynı kas grubu alternatifleri',
      'add_to_workout': 'Antrenmana Ekle',
      'select_workout': 'Antrenman Seç',
      'manual_duration': 'Manuel Süre',
      'enter_duration_min': 'Süre girin (dk)',
      'first_day_of_week': 'Haftanın İlk Günü',
      'avg_volume_per_workout': 'Antrenman başına ort. hacim',
      'avg_duration_per_workout': 'Antrenman başına ort. süre',
      'avg_sets_per_workout': 'Antrenman başına ort. set',
      'best_workout': 'En iyi antrenman',
      'day': 'Gün',
    },

    // ═══════════════════════════════════════════════════
    //  SPANISH
    // ═══════════════════════════════════════════════════
    'es': {
      // Navigation
      'home': 'Inicio',
      'workouts': 'Entrenamientos',
      'library': 'Biblioteca',
      'stats': 'Estadísticas',

      // Settings
      'settings': 'Ajustes',
      'profile': 'Perfil',
      'my_body_stats': 'Mis Medidas Corporales',
      'preferences': 'Preferencias',
      'theme': 'Tema',
      'language': 'Idioma',
      'measurement_system': 'Sistema de Medidas',
      'metric': 'Métrico',
      'imperial': 'Imperial',
      'data_management': 'Gestión de Datos',
      'backup_database': 'Copia de Seguridad',
      'backup_desc': 'Guardar sus datos en un archivo',
      'restore_database': 'Restaurar Base de Datos',
      'restore_desc': 'Cargar datos desde un archivo de respaldo',
      'restore_confirm':
          '¿Está seguro? Esto sobrescribirá todos los datos actuales con la copia de respaldo.',
      'restore_title': 'Restaurar Copia de Seguridad',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'restore': 'Restaurar',
      'edit_profile': 'Editar Perfil',
      'edit_body_stats': 'Editar Medidas Corporales',
      'height': 'Altura',
      'weight': 'Peso',
      'system_theme': 'Sistema',
      'dark_theme': 'Oscuro',
      'light_theme': 'Claro',
      'english': 'English',
      'turkish': 'Türkçe',
      'spanish': 'Español',
      'german': 'Deutsch',
      'french': 'Français',

      // Body stats
      'body_measurements': 'Medidas Corporales',
      'arm_circumference': 'Brazo',
      'waist_circumference': 'Cintura',
      'shoulder_width': 'Hombros',
      'chest_circumference': 'Pecho',
      'hip_circumference': 'Cadera',
      'thigh_circumference': 'Muslo',
      'calf_circumference': 'Pantorrilla',
      'neck_circumference': 'Cuello',
      'forearm_circumference': 'Antebrazo',
      'body_progress': 'Progreso Corporal',
      'update_measurements': 'Actualizar Medidas',
      'no_measurements_yet':
          'Aún no hay mediciones registradas.\nToque el botón para agregar su primera medición.',
      'measurement_saved': '¡Medidas guardadas correctamente!',
      'select_measurement': 'Seleccionar Medida',

      // Home
      'next_training': 'Próximo Entrenamiento',
      'weekly_overview': 'Resumen Semanal',
      'volume': 'Volumen',
      'reps': 'Repeticiones',
      'sets': 'Series',
      'muscle_groups': 'Grupos Musculares',
      'calories_burned': 'Calorías Quemadas (kcal)',
      'more': 'Más',
      'last': 'Último',
      'week': 'Semana',
      'month': 'Mes',
      'all_time': 'Todo el Tiempo',
      'no_routines':
          "No hay rutinas creadas. Toque 'Entrenamientos' para crear una.",
      'workout_in_progress': 'Entrenamiento en curso',
      'scheduled_routines': 'Rutinas Programadas',
      'completed_workouts': 'Entrenamientos Completados',
      'rest_day': 'Día de Descanso 😌',
      'start_free_workout': 'Iniciar Entrenamiento Libre',
      'auto_scheduled': 'Programación Automática',
      'every': 'Cada',
      'no_workout_data_yet': 'Aún no hay datos de entrenamiento',
      'no_calorie_data_yet': 'Aún no hay datos de calorías',
      'sets_label': 'series',

      // Active Workout
      'no_active_workout': 'Sin entrenamiento activo',
      'add_exercise': 'Agregar Ejercicio',
      'finish': 'Terminar',
      'rest_timer': 'Temporizador de Descanso',
      'exercise': 'Ejercicio',

      // Workout History
      'add_workout': 'Agregar Entrenamiento',
      'my_workout': 'Mi Entrenamiento',
      'no_routines_created':
          '¡No hay rutinas creadas aún. Cree una para empezar!',
      'all_past_workouts': 'Entrenamientos Anteriores',
      'no_workouts_found': 'No se encontraron entrenamientos',
      'delete': 'Eliminar',
      'delete_workout_confirm': '¿Desea eliminar este entrenamiento?',
      'workout_completed': '¡Entrenamiento Completado!',

      // Stats
      'total_workouts': 'Total de Entrenamientos',
      'total_volume': 'Volumen Total',
      'total_sets': 'Series Totales',
      'total_duration': 'Duración Total',

      // Units
      'kg': 'kg',
      'lbs': 'lbs',
      'cm': 'cm',
      'in': 'pulg',
      'ft': 'pie',

      // Misc
      'no_data': 'Sin datos',
      'exercises_label': 'ejercicios',
      'storage_permission_required':
          'Se requiere permiso de almacenamiento para realizar la copia de seguridad. Concédalo en Ajustes.',
      'open_settings': 'Abrir Ajustes',
      'backup_saved': 'Copia de seguridad guardada correctamente',
      'backup_failed': 'Error al crear la copia de seguridad',
      'restore_success':
          '¡Restauración exitosa! Los datos han sido recargados.',
      'restore_failed': 'Error al restaurar los datos',
      'file_not_found': 'El archivo seleccionado no fue encontrado.',
      'workout_details': 'Detalles del Entrenamiento',

      // Rest Timer Notifications
      'rest_started': 'Tiempo de Descanso',
      'rest_finished': '¡Descanso Terminado!',
      'rest_finished_body': '¡Es hora del siguiente set! 💪',
      'resting': 'Descansando',

      // Color Palette
      'color_palette': 'Paleta de Colores',
      'color_palette_desc': 'Personalizar los colores de la aplicación',
      'palette_default': 'Morado Predeterminado',
      'palette_ocean': 'Azul Océano',
      'palette_sunset': 'Naranja Atardecer',
      'palette_forest': 'Verde Bosque',
      'palette_rose': 'Rosa',
      'palette_crimson': 'Rojo Carmesí',
      'appearance': 'Apariencia',
      'background_mode': 'Fondo',
      'bg_default': 'Predeterminado',
      'pure_black': 'Negro Puro (AMOLED)',

      // Days
      'mon': 'Lun',
      'tue': 'Mar',
      'wed': 'Mié',
      'thu': 'Jue',
      'fri': 'Vie',
      'sat': 'Sáb',
      'sun': 'Dom',
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',

      // New features
      'alternative_exercise': 'Ejercicio Alternativo',
      'swap_exercise': 'Cambiar Ejercicio',
      'same_muscle_group': 'Alternativas del mismo grupo muscular',
      'add_to_workout': 'Agregar al Entrenamiento',
      'select_workout': 'Seleccionar Entrenamiento',
      'manual_duration': 'Duración Manual',
      'enter_duration_min': 'Ingrese duración (min)',
      'first_day_of_week': 'Primer día de la semana',
      'avg_volume_per_workout': 'Volumen promedio por entrenamiento',
      'avg_duration_per_workout': 'Duración promedio por entrenamiento',
      'avg_sets_per_workout': 'Series promedio por entrenamiento',
      'best_workout': 'Mejor entrenamiento',
      'day': 'Día',
    },

    // ═══════════════════════════════════════════════════
    //  GERMAN (partial, fallback to EN for missing keys)
    // ═══════════════════════════════════════════════════
    'de': {
      'home': 'Startseite',
      'workouts': 'Trainings',
      'library': 'Bibliothek',
      'stats': 'Statistiken',
      'settings': 'Einstellungen',
      'profile': 'Profil',
      'preferences': 'Präferenzen',
      'theme': 'Design',
      'language': 'Sprache',
      'measurement_system': 'Maßeinheitensystem',
      'metric': 'Metrisch',
      'imperial': 'Imperial',
      'english': 'English',
      'turkish': 'Türkçe',
      'spanish': 'Español',
      'german': 'Deutsch',
      'french': 'Français',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'finish': 'Beenden',
      'next_training': 'Nächstes Training',
      'weekly_overview': 'Wochenübersicht',
      'rest_day': 'Ruhetag 😌',
      'start_free_workout': 'Freies Training starten',
      'total_workouts': 'Gesamtzahl Trainings',
      'total_volume': 'Gesamtvolumen',
      'total_sets': 'Gesamtsätze',
      'total_duration': 'Gesamtdauer',
      'rest_started': 'Pausenzeit',
      'rest_finished': 'Pause beendet!',
      'rest_finished_body': 'Zeit für deinen nächsten Satz! 💪',
      'monday': 'Montag',
      'tuesday': 'Dienstag',
      'wednesday': 'Mittwoch',
      'thursday': 'Donnerstag',
      'friday': 'Freitag',
      'saturday': 'Samstag',
      'sunday': 'Sonntag',
      'mon': 'Mo',
      'tue': 'Di',
      'wed': 'Mi',
      'thu': 'Do',
      'fri': 'Fr',
      'sat': 'Sa',
      'sun': 'So',
      'day': 'Tag',
    },

    // ═══════════════════════════════════════════════════
    //  FRENCH (partial, fallback to EN for missing keys)
    // ═══════════════════════════════════════════════════
    'fr': {
      'home': 'Accueil',
      'workouts': 'Entraînements',
      'library': 'Bibliothèque',
      'stats': 'Statistiques',
      'settings': 'Paramètres',
      'profile': 'Profil',
      'preferences': 'Préférences',
      'theme': 'Thème',
      'language': 'Langue',
      'measurement_system': 'Système de mesure',
      'metric': 'Métrique',
      'imperial': 'Impérial',
      'english': 'English',
      'turkish': 'Türkçe',
      'spanish': 'Español',
      'german': 'Deutsch',
      'french': 'Français',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'finish': 'Terminer',
      'next_training': 'Prochain entraînement',
      'weekly_overview': 'Résumé hebdomadaire',
      'rest_day': 'Jour de repos 😌',
      'start_free_workout': 'Commencer un entraînement libre',
      'total_workouts': 'Total des entraînements',
      'total_volume': 'Volume total',
      'total_sets': 'Total des séries',
      'total_duration': 'Durée totale',
      'rest_started': 'Temps de repos',
      'rest_finished': 'Repos terminé !',
      'rest_finished_body': 'Il est temps pour ta prochaine série ! 💪',
      'monday': 'Lundi',
      'tuesday': 'Mardi',
      'wednesday': 'Mercredi',
      'thursday': 'Jeudi',
      'friday': 'Vendredi',
      'saturday': 'Samedi',
      'sunday': 'Dimanche',
      'mon': 'Lun',
      'tue': 'Mar',
      'wed': 'Mer',
      'thu': 'Jeu',
      'fri': 'Ven',
      'sat': 'Sam',
      'sun': 'Dim',
      'day': 'Jour',
    },
  };
}
