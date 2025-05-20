import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final uuid = Uuid();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация часовых поясов
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Moscow'));

  // Настройка уведомлений
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: initializationSettingsAndroid,
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const EventsScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Event Timer',
            theme: themeProvider.currentTheme,
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final DateTime date;

  Event({
    required this.id,
    required this.title,
    required this.date,
  });
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  ThemeData get currentTheme => _themeMode == ThemeMode.light
      ? ThemeData.light()
      : ThemeData.dark();

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class EventsProvider with ChangeNotifier {
  List<Event> _events = [];

  List<Event> get events => _events;

  Future<void> addEvent(Event event) async {
    _events.add(event);
    notifyListeners();
    await _scheduleNotification(event);
  }

  Future<void> _scheduleNotification(Event event) async {
    if (await _requestAndroidPermissions()) {
      final androidDetails = AndroidNotificationDetails(
        'event_channel',
        'Event Notifications',
        channelDescription: 'Channel for event reminders',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final scheduledTime = tz.TZDateTime.from(
        event.date.subtract(const Duration(minutes: 30)),
        tz.local,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        event.id.hashCode,
        'Событие приближается!',
        event.title,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 🔧 ОБЯЗАТЕЛЬНО
        matchDateTimeComponents: DateTimeComponents.time, // или null, если не нужно повторение
      );
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Timer'),
        actions: [
          IconButton(
            icon: Icon(context.watch<ThemeProvider>().themeMode == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: Consumer<EventsProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.events.length,
            itemBuilder: (context, index) {
              final event = provider.events[index];
              return _EventItem(
                event: event,
                isCountdown: _selectedTab == 0,
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'До события',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Прошедшее время',
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(),
    );
  }
}

class _EventItem extends StatelessWidget {
  final Event event;
  final bool isCountdown;

  const _EventItem({required this.event, required this.isCountdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _TimerWidget(
              targetDate: event.date,
              isCountdown: isCountdown,
            ),
          ],
        ).animate().fadeIn().slideX(),
      ),
    );
  }
}

class _TimerWidget extends StatefulWidget {
  final DateTime targetDate;
  final bool isCountdown;

  const _TimerWidget({required this.targetDate, required this.isCountdown});

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  Duration _duration = Duration.zero;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _duration = widget.isCountdown
          ? widget.targetDate.difference(now)
          : now.difference(widget.targetDate);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_duration.inHours}:${(_duration.inMinutes % 60).toString().padLeft(2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class AddEventDialog extends StatefulWidget {
  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить событие'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Название события'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickDate,
            child: Text('Выбрать дату: ${DateFormat.yMd().format(_selectedDate)}'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveEvent,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) return;

    final event = Event(
      id: uuid.v4(),
      title: _titleController.text,
      date: _selectedDate,
    );

    context.read<EventsProvider>().addEvent(event);
    Navigator.pop(context);
  }
}