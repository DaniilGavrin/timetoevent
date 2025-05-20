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
    _loadEvents();
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _events.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(jsonList));
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString != null) {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      _events = jsonList.map((e) => Event.fromJson(e)).cast<Event>().toList();
    }
    notifyListeners();
  }

  Future<void> addEvent(Event event) async {
    _events.add(event);
    await _saveEvents();
    notifyListeners();
    await _scheduleNotification(event);
  }

  Future<void> removeEvent(String eventId) async {
    _events.removeWhere((event) => event.id == eventId);
    await _saveEvents();
    notifyListeners();
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
      final notificationDetails = NotificationDetails(android: androidDetails);

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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
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