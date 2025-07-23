import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timetoevent/providers/SettingsProvider.dart';
import 'package:timetoevent/providers/localization_provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language') ?? 'ru';

  final savedThemeMode = await ThemeProvider.loadThemeMode();

  // Инициализация часовых поясов
  try {
    tz_data.initializeTimeZones();
    final prefs = await SharedPreferences.getInstance();
    final savedTimeZone = prefs.getString('time_zone') ?? 'Europe/Moscow';
    tz.setLocalLocation(tz.getLocation(savedTimeZone));
  } catch (e) {
    print('Ошибка инициализации часового пояса: $e');
    tz.setLocalLocation(tz.UTC);
  }

  await initializeDateFormatting('ru');

  await FlutterLocalization.instance.ensureInitialized();

  final settingsProvider = SettingsProvider();

  // Инициализация локализации
  FlutterLocalization.instance.init(
    mapLocales: [
      MapLocale('en', AppLocale.EN),
      MapLocale('ru', AppLocale.RU),
    ],
    initLanguageCode: 'ru',
  );

  await ThemeProvider.loadThemeMode();

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
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => settingsProvider),
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