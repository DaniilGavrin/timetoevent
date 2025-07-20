mixin AppLocale {
  // Существующие ключи
  static const String settings = 'settings';
  static const String time_zone = 'time_zone';
  static const String language = 'language';
  static const String select_time_zone = 'select_time_zone';
  static const String search_time_zones = 'search_time_zones';

  // Новые ключи для EventsScreen
  static const String app_title = 'app_title';
  static const String future_events = 'future_events';
  static const String retro_events = 'retro_events';
  static const String past_events = 'past_events';
  static const String no_events = 'no_events';
  static const String add_event_button = 'add_event_button';
  static const String delete_event_title = 'delete_event_title';
  static const String delete_event_content = 'delete_event_content';
  static const String cancel = 'cancel';
  static const String delete = 'delete';

  // Локализованные данные
  static const Map<String, dynamic> EN = {
    settings: 'Settings',
    time_zone: 'Time Zone',
    language: 'Language',
    select_time_zone: 'Select Time Zone',
    search_time_zones: 'Search Time Zones',
    app_title: 'Event Timer',
    future_events: 'Future Events',
    retro_events: 'Retro Events',
    past_events: 'Past Events',
    no_events: 'No events',
    add_event_button: 'Add Event',
    delete_event_title: 'Delete Event',
    delete_event_content: 'Delete',
    cancel: 'Cancel',
    delete: 'Delete',
  };

  static const Map<String, dynamic> RU = {
    settings: 'Настройки',
    time_zone: 'Часовой пояс',
    language: 'Язык',
    select_time_zone: 'Выбор часового пояса',
    search_time_zones: 'Поиск часовых поясов',
    app_title: 'Таймер событий',
    future_events: 'Будущие события',
    retro_events: 'Ретро события',
    past_events: 'Прошедшие события',
    no_events: 'Нет событий',
    add_event_button: 'Добавить событие',
    delete_event_title: 'Удалить событие',
    delete_event_content: 'Удалить',
    cancel: 'Отмена',
    delete: 'Удалить',
  };
}