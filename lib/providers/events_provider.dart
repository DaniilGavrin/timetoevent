import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  void removeEvent(String eventId) {
    _events.removeWhere((event) => event.id == eventId);
    notifyListeners();
  }
}