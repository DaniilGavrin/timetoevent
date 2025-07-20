mixin AppLocale {
  // Ключи для строк
  static const String settings = 'settings';
  static const String time_zone = 'time_zone';
  static const String language = 'language';
  static const String select_time_zone = 'select_time_zone';
  static const String search_time_zones = 'search_time_zones';

  // Локализованные данные
  static const Map<String, dynamic> EN = {
    settings: 'Settings',
    time_zone: 'Time Zone',
    language: 'Language',
    select_time_zone: 'Select Time Zone',
    search_time_zones: 'Search Time Zones',
  };

  static const Map<String, dynamic> RU = {
    settings: 'Настройки',
    time_zone: 'Часовой пояс',
    language: 'Язык',
    select_time_zone: 'Выбор часового пояса',
    search_time_zones: 'Поиск часовых поясов',
  };
}