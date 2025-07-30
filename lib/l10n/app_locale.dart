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
  static const String search_language = 'search_language';
  static const String add_event_prompt = 'add_event_prompt'; // Новая подсказка

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

  static const String update_interval = 'update_interval';
  static const String update_interval_seconds = 'update_interval_seconds';

  static const String system = 'system';
  static const String light = 'light';
  static const String dark = 'dark';
  static const String theme_mode = 'theme_mode';
  static const String select_theme = 'select_theme';

  static const String faq_title = 'faq_title';
  static const String faq_description = 'faq_description';
  static const String faq_item_1_question = 'faq_item_1_question';
  static const String faq_item_1_answer = 'faq_item_1_answer';
  static const String faq_item_2_question = 'faq_item_2_question';
  static const String faq_item_2_answer = 'faq_item_2_answer';
  static const String faq_item_3_question = 'faq_item_3_question';
  static const String faq_item_3_answer = 'faq_item_3_answer';

  static const String edit = "edit";
  static const String edit_event = "edit_event";
  static const String enter_event_title = "enter_event_title";
  static const String event_title_required = "event_title_required";
  static const String error_saving_event = "error_saving_event";
  static const String event_date_time = "event_date_time";
  static const String select_date = "select_date";
  static const String select_time = "select_time";
  static const String countdown_description = "countdown_description";
  static const String timestamp = "timestamp";
  static const String timestamp_description = "timestamp_description";
  static const String retroactive_description = "retroactive_description";

  static const String back = "back";

  static const Map<String, dynamic> EN = {
    settings: 'Settings',
    time_zone: 'Time Zone',
    language: 'Language',
    english: 'English',
    russian: 'Russian',
    search_language: 'Search Language',
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

    update_interval: 'Update Interval',
    update_interval_seconds: 'Update Interval (seconds)',
    add_event_prompt: 'Create your first event to start tracking',

    system: 'System',
    light: 'Light',
    dark: 'Dark',
    theme_mode: 'Theme',
    select_theme: 'Select Theme',

    faq_title: 'Frequently Asked Questions',
    faq_description: 'Find answers to common questions about the app.',
    faq_item_1_question: 'How do I change the language?',
    faq_item_1_answer: 'Go to Settings → Language and choose your preferred language.',
    faq_item_2_question: 'How do I change the app theme?',
    faq_item_2_answer: 'Go to Settings → Theme and choose Light, Dark, or System.',
    faq_item_3_question: 'How do I add a new event?',
    faq_item_3_answer: 'Tap the + button on the home screen and fill in the event details.',
    
    edit: "Edit",
    edit_event: "Edit Event",
    enter_event_title: "Enter event title",
    event_title_required: "Event title is required",
    error_saving_event: "Error saving event",
    event_date_time: "Event Date & Time",
    select_date: "Select Date",
    select_time: "Select Time",
    countdown_description: "Count down to a specific date",
    timestamp: "Timestamp",
    timestamp_description: "Track time since a specific date",
    retroactive_description: "Track time since a specific date",

    back: "Back"
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
    search_language: 'Поиск языка',

    update_interval: 'Интервал обновления',
    update_interval_seconds: 'Интервал обновления (секунды)',
    add_event_prompt: 'Создайте первое событие, чтобы начать отслеживание',

    system: 'Системная',
    light: 'Светлая',
    dark: 'Темная',
    theme_mode: 'Тема',
    select_theme: 'Выбор темы',

    faq_title: 'Часто задаваемые вопросы',
    faq_description: 'Ниже приведены ответы на распространенные вопросы.',
    faq_item_1_question: 'Как изменить язык приложения?',
    faq_item_1_answer: 'Перейдите в Настройки → Язык и выберите нужный язык.',
    faq_item_2_question: 'Как изменить тему приложения?',
    faq_item_2_answer: 'Перейдите в Настройки → Тема и выберите Светлая, Тёмная или Системная.',
    faq_item_3_question: 'Как добавить новое событие?',
    faq_item_3_answer: 'Нажмите кнопку + на главном экране и заполните данные события.',
    
    edit: "Редактировать",
    edit_event: "Редактировать событие",
    enter_event_title: "Введите название события",
    event_title_required: "Требуется название события",
    error_saving_event: "Ошибка сохранения события",
    event_date_time: "Дата и время события",
    select_date: "Выбрать дату",
    select_time: "Выбрать время",
    countdown_description: "Обратный отсчет до определенной даты",
    timestamp: "Метка времени",
    timestamp_description: "Отслеживание времени с определенной даты",
    retroactive_description: "Отслеживание времени с определенной даты",

    back: "Назад"
  };
}