mixin AppLocale {
  // Основные ключи для локализации
  static const String settings = 'settings';
  static const String time_zone = 'time_zone';
  static const String language = 'language';
  static const String english = 'english';
  static const String russian = 'russian';
  static const String select_time_zone = 'select_time_zone';
  static const String search_time_zones = 'search_time_zones';
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

  // Ключи для AddEventDialog
  static const String new_event = 'new_event';
  static const String event_title = 'event_title';
  static const String date = 'date';
  static const String time = 'time';
  static const String event_type = 'event_type';
  static const String countdown = 'countdown';
  static const String retro = 'retro';
  static const String save = 'save';

  // Ключи для EventDetailsScreen
  static const String until_event = 'until_event';
  static const String since_event = 'since_event';
  static const String days = 'days';
  static const String hours = 'hours';
  static const String minutes = 'minutes';
  static const String seconds = 'seconds';
  static const String percent = 'percent';

  static const Map<String, dynamic> EN = {
    settings: 'Settings',
    time_zone: 'Time Zone',
    language: 'Language',
    english: 'English',
    russian: 'Russian',
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
    new_event: 'New Event',
    event_title: 'Event Title',
    date: 'Date',
    time: 'Time',
    event_type: 'Event Type',
    countdown: 'Countdown',
    retro: 'Retro',
    save: 'Save',
    // Новые строки для EventDetailsScreen
    until_event: 'Until event',
    since_event: 'Since event',
    days: 'd',
    hours: 'h',
    minutes: 'm',
    seconds: 's',
    percent: '%',
  };

  static const Map<String, dynamic> RU = {
    settings: 'Настройки',
    time_zone: 'Часовой пояс',
    language: 'Язык',
    english: 'Английский',
    russian: 'Русский',
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
    new_event: 'Новое событие',
    event_title: 'Название события',
    date: 'Дата',
    time: 'Время',
    event_type: 'Тип события',
    countdown: 'Отсчет',
    retro: 'Ретро',
    save: 'Сохранить',
    until_event: 'До события',
    since_event: 'С момента события',
    days: 'д',
    hours: 'ч',
    minutes: 'м',
    seconds: 'с',
    percent: '%',
  };
}