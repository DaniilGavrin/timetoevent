import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timetoevent/screens/premium_screen.dart';
import 'package:timetoevent/screens/settings_screen.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'providers/theme_provider.dart';
import 'providers/events_provider.dart';
import 'screens/events_screen.dart';
import 'screens/event_details_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация часовых поясов
  try {
    tz_data.initializeTimeZones(); // 1. Правильный метод инициализации
    final prefs = await SharedPreferences.getInstance();
    final savedTimeZone = prefs.getString('time_zone') ?? 'Europe/Moscow';
    tz.setLocalLocation(tz.getLocation(savedTimeZone));
  } catch (e) {
    print('Ошибка инициализации часового пояса: $e');
    tz.setLocalLocation(tz.UTC);
  }

  await initializeDateFormatting('ru');

  final savedThemeMode = await ThemeProvider.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialThemeMode: savedThemeMode),
        ),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

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
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      )
    ],
  );

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
        );
      },
    );
  }
}