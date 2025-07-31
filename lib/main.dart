import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timetoevent/models/event.dart';
import 'package:timetoevent/providers/SettingsProvider.dart';
import 'package:timetoevent/providers/localization_provider.dart';
import 'package:timetoevent/screens/event_edit_screen.dart';
import 'package:timetoevent/screens/faq_screen.dart';
import 'package:timetoevent/screens/settings_screen.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'providers/theme_provider.dart';
import 'providers/events_provider.dart';
import 'screens/events_screen.dart';
import 'screens/event_details_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'l10n/app_locale.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


Future<void> _initializeNotificationChannel() async {
  print('[EventsProvider] Initializing notification channel...');
  
  try {
    // Настройки для Android
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Настройки для iOS
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    

    const WindowsInitializationSettings windowsSettings =
    WindowsInitializationSettings(
        appName: 'Flutter Local Notifications Example',
        appUserModelId: 'com.bytewizard.timetoevent',
        guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb'
    );

    final LinuxInitializationSettings linuxSettings =
    LinuxInitializationSettings(
        defaultActionName: 'Open notification');
    
    // Объединяем настройки для всех платформ
    final initializationSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosSettings,
      windows: windowsSettings,
      linux: linuxSettings,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('[EventsProvider] Notification channel initialized successfully for all platforms');
  } catch (error, stackTrace) {
    print('[EventsProvider] ERROR initializing notification channel: $error');
    print('[EventsProvider] Stack trace: $stackTrace');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language') ?? 'ru';
  final savedThemeMode = await ThemeProvider.loadThemeMode();

  try {
    // Инициализация плагина локальных уведомлений
    await _initializeNotificationChannel();
  } catch (error) {
    print('[EventsProvider] ERROR initializing local notifications: $error');
  }

  // Инициализация часовых поясов
  tz_data.initializeTimeZones();
  final savedTimeZone = prefs.getString('time_zone') ?? 'Europe/Moscow';
  tz.setLocalLocation(tz.getLocation(savedTimeZone));

  // Инициализация локализации
  await initializeDateFormatting('ru');
  await FlutterLocalization.instance.ensureInitialized();

  FlutterLocalization.instance.init(
    mapLocales: [
      MapLocale('en', AppLocale.EN),
      MapLocale('ru', AppLocale.RU),
    ],
    initLanguageCode: savedLanguage,
  );
  /*
  Future.delayed(const Duration(seconds: 5), () async {
    print('[DEBUG] Sending test notification...');
    await flutterLocalNotificationsPlugin.show(
      0,
      'Тест уведомления',
      'Если вы видите это, то уведомления работают!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          importance: Importance.high,
        ),
        windows: WindowsNotificationDetails(),
      ),
    );
    print('[DEBUG] Test notification sent');
  });
  */
  final eventsProvider = EventsProvider();
  await eventsProvider.loadEvents(); // Загрузите события
  await eventsProvider.rescheduleNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = LocalizationProvider();
            provider.initLanguageFromPrefs(savedLanguage);
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialThemeMode: savedThemeMode),
        ),
        ChangeNotifierProvider(create: (_) => eventsProvider),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventDetailsScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/event/:id/edit',
        builder: (context, state) {
          final eventId = state.pathParameters['id']!;
          return EventEditScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/faq',
        builder: (context, state) => const FaqScreen(),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();

    // Подписка на обновление языка
    FlutterLocalization.instance.onTranslatedLanguage = (locale) {
      setState(() {}); // Обновляет UI при смене языка
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          routerConfig: _router,
          title: 'Event Timer Pro',
          theme: themeProvider.currentTheme,
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          // Добавлены делегаты и поддерживаемые локали
          localizationsDelegates: FlutterLocalization.instance.localizationsDelegates,
          supportedLocales: FlutterLocalization.instance.supportedLocales,
        );
      },
    );
  }
}