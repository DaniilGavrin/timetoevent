import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../models/event.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
final uuid = Uuid();

class EventsProvider with ChangeNotifier {
  List<Event> _events = [];
  List<Event> get events => _events;

  final String _prefsKey = 'events_list';

  EventsProvider() {
    loadEvents();
  }

  Future<void> saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Сначала преобразуем события в List<Map<String, dynamic>>
    final List<Map<String, dynamic>> eventsMapList = _events.map((event) => event.toJson()).toList();
    
    // Затем преобразуем в List<String> через jsonEncode
    final List<String> eventJsonList = eventsMapList.map((map) => jsonEncode(map)).toList();
    
    // Сохраняем как List<String> в SharedPreferences
    await prefs.setStringList('events', eventJsonList);
  }

  Future<void> loadEvents() async {
    // Загрузите события из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final List<String> eventJsonList = prefs.getStringList('events') ?? [];
    _events = eventJsonList.map((json) {
      final Map<String, dynamic> data = jsonDecode(json);
      final tz.Location location = tz.getLocation(data['timezone'] ?? 'Europe/Moscow');
      return Event(
        id: data['id'],
        title: data['title'],
        date: tz.TZDateTime.fromMillisecondsSinceEpoch(location, data['date']),
        eventType: EventType.values.byName(data['eventType']),
      );
    }).toList();
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    _events.add(event);
    await saveEvents();
    await scheduleEventNotification(event);
    notifyListeners();
  }

  Future<void> removeEvent(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
    await saveEvents();
    notifyListeners();
  }

  Future<void> scheduleEventNotification(Event event) async {
    final tz.TZDateTime scheduledDate = event.date;
    final now = tz.TZDateTime.now(tz.local);

    if (scheduledDate.isBefore(now)) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'event_timer_channel',
      'Event Timer',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      event.hashCode,
      'Событие завершено',
      'Ваше событие "${event.title}" завершено.',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exact, // Вместо androidAllowWhileIdle
      payload: jsonEncode(event.toJson()),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelEventNotification(String eventId) async {
    await flutterLocalNotificationsPlugin.cancel(eventId.hashCode);
  }

  Future<void> rescheduleNotifications() async {
    for (var event in _events) {
      await scheduleEventNotification(event);
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