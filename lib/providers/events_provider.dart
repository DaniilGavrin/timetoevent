import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    print('[EventsProvider] Initializing EventsProvider...');
    loadEvents().then((_) {
      print('[EventsProvider] Events loaded successfully');
    }).catchError((error) {
      print('[EventsProvider] Error loading events: $error');
    });
  }

  Future<void> saveEvents() async {
    print('[EventsProvider] Saving events to SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      print('[EventsProvider] SharedPreferences instance obtained');
      
      // Сначала преобразуем события в List<Map<String, dynamic>>
      final List<Map<String, dynamic>> eventsMapList = _events.map((event) {
        print('[EventsProvider] Converting event to JSON: ${event.id}');
        return event.toJson();
      }).toList();
      
      // Затем преобразуем в List<String> через jsonEncode
      final List<String> eventJsonList = eventsMapList.map((map) {
        final jsonString = jsonEncode(map);
        print('[EventsProvider] Event JSON: $jsonString');
        return jsonString;
      }).toList();

      _requestAndroidPermissions().then((granted) {
        if (granted) {
          print('[EventsProvider] Android permissions granted');
        } else {
          print('[EventsProvider] Android permissions not granted');
        }
      }).catchError((error) {
        print('[EventsProvider] Error requesting Android permissions: $error');
      });
      
      // Сохраняем как List<String> в SharedPreferences
      await prefs.setStringList('events', eventJsonList);
      print('[EventsProvider] Events saved successfully. Total: ${eventJsonList.length}');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR saving events: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
    }
  }

  Future<void> loadEvents() async {
    print('[EventsProvider] Loading events from SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      print('[EventsProvider] SharedPreferences instance obtained');
      
      final List<String>? eventJsonList = prefs.getStringList('events');
      print('[EventsProvider] Events JSON list: $eventJsonList');
      
      if (eventJsonList == null || eventJsonList.isEmpty) {
        print('[EventsProvider] No events found in SharedPreferences');
        _events = [];
        notifyListeners();
        return;
      }
      
      print('[EventsProvider] Found ${eventJsonList.length} events in SharedPreferences');
      
      _events = eventJsonList.map((json) {
        try {
          print('[EventsProvider] Parsing event JSON: $json');
          final Map<String, dynamic> data = jsonDecode(json);
          
          // Получаем часовой пояс из данных события или используем Московский по умолчанию
          final String timezone = data['timezone'] ?? 'Europe/Moscow';
          print('[EventsProvider] Event timezone: $timezone');
          
          final tz.Location location = tz.getLocation(timezone);
          print('[EventsProvider] Location obtained: ${location.name}');
          
          // ПРАВИЛЬНЫЙ СПОСОБ ПАРСИНГА ДАТЫ С УЧЕТОМ ЧАСОВОГО ПОЯСА
          final tz.TZDateTime date = tz.TZDateTime.parse(location, data['date']);
          
          final tz.TZDateTime? createdAt = data['createdAt'] != null
              ? tz.TZDateTime.parse(location, data['createdAt'])
              : null;
          
          // Создаем событие
          final event = Event(
            id: data['id'],
            title: data['title'],
            date: date,
            eventType: EventType.values.byName(data['eventType']),
            createdAt: createdAt,
          );
          
          print('[EventsProvider] Event created: ${event.id} - ${event.title}');
          print('[EventsProvider] Event date: ${event.date.toIso8601String()}');
          
          return event;
        } catch (error, stackTrace) {
          print('[EventsProvider] ERROR parsing event: $error');
          print('[EventsProvider] Stack trace: $stackTrace');
          rethrow;
        }
      }).toList();
      
      print('[EventsProvider] Events loaded successfully. Total: ${_events.length}');
      notifyListeners();
      
      // После загрузки событий перезапускаем уведомления
      print('[EventsProvider] Rescheduling notifications after loading events...');
      rescheduleNotifications().then((_) {
        print('[EventsProvider] Notifications rescheduled successfully');
      }).catchError((error) {
        print('[EventsProvider] Error rescheduling notifications: $error');
      });
    } catch (error, stackTrace) {
      print('[EventsProvider] CRITICAL ERROR loading events: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      _events = [];
      notifyListeners();
    }
  }

  Future<void> addEvent(Event event) async {
    print('[EventsProvider] Adding new event: ${event.id} - ${event.title}');
    
    try {
      _events.add(event);
      print('[EventsProvider] Event added to local list. Total events: ${_events.length}');
      
      await saveEvents();
      print('[EventsProvider] Events saved after adding new event');
      
      await scheduleEventNotification(event);
      print('[EventsProvider] Notification scheduled for new event');
      
      notifyListeners();
      print('[EventsProvider] UI updated after adding event');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR adding event: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateEvent(Event updatedEvent) async {
    final index = events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      // Сначала отменяем старое уведомление
      await cancelEventNotification(updatedEvent.id);
      
      // Заменяем событие
      events[index] = updatedEvent;
      
      // Планируем новое уведомление
      await scheduleEventNotification(updatedEvent);
      
      // Сохраняем изменения
      await saveEvents();
      
      // Уведомляем слушателей
      notifyListeners();
    }
  }

  Future<void> removeEvent(String eventId) async {
    print('[EventsProvider] Removing event: $eventId');
    
    try {
      Event? event = _events.firstWhere((e) => e.id == eventId, orElse: () => null as dynamic);
      if (event == null) {
        print('[EventsProvider] Event not found: $eventId');
        return;
      }
      if (event != null) {
        print('[EventsProvider] Event found: ${event.title}');
        await cancelEventNotification(eventId);
        print('[EventsProvider] Notification canceled for event');
      } else {
        print('[EventsProvider] Event not found in local list');
      }
      
      _events.removeWhere((event) => event.id == eventId);
      print('[EventsProvider] Event removed from local list. Total events: ${_events.length}');
      
      await saveEvents();
      print('[EventsProvider] Events saved after removing event');
      
      notifyListeners();
      print('[EventsProvider] UI updated after removing event');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR removing event: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> scheduleEventNotification(Event event) async {
    print('[EventsProvider] Scheduling notification for event: ${event.id}');
    
    try {
      final tz.TZDateTime scheduledDate = event.date;
      final now = tz.TZDateTime.now(tz.local);
      
      print('[EventsProvider] Event date (local): ${scheduledDate.toIso8601String()}');
      print('[EventsProvider] Current date (local): ${now.toIso8601String()}');
      
      final Duration difference = scheduledDate.difference(now);
      print('[EventsProvider] Time until event: ${difference.inHours}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s');
      
      if (scheduledDate.isBefore(now)) {
        print('[EventsProvider] Event has already passed. Skipping notification.');
        return;
      }
      
      // Настройки для Android
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'event_timer_channel',
        'Event Timer Notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        fullScreenIntent: true,
      );

      final WindowsNotificationDetails windowsPlatformChannelSpecifics =
          const WindowsNotificationDetails();

      final LinuxNotificationDetails linuxPlatformChannelSpecifics =
          const LinuxNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        windows: windowsPlatformChannelSpecifics,
        linux: linuxPlatformChannelSpecifics,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      print('[EventsProvider] Preparing payload...');
      final String payload = jsonEncode(event.toJson());
      print('[EventsProvider] Notification payload: $payload');
      
      print('[EventsProvider] Scheduling zoned notification...');
      await flutterLocalNotificationsPlugin.zonedSchedule(
        event.hashCode,
        'Событие завершено',
        'Ваше событие "${event.title}" завершено.',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      print('[EventsProvider] Notification scheduled successfully for event: ${event.id}');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR scheduling notification: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      
      if (error is PlatformException) {
        print('[EventsProvider] PlatformException code: ${error.code}');
        print('[EventsProvider] PlatformException message: ${error.message}');
      }
    }
  }

  Future<void> _initializeNotificationChannel() async {
    print('[EventsProvider] Initializing notification channel...');
    
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'event_timer_channel',
        'Event Timer Notifications',
        importance: Importance.high,
        enableVibration: true,
      );
      
      print('[EventsProvider] Channel created: $channel');
      
      // createNotificationChannel возвращает void, поэтому не сохраняем результат
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
          
      print('[MainChannel] Notifi 2 channel');
      print('[EventsProvider] Notification channel initialized successfully');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR initializing notification channel: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
    }
  }

  Future<void> cancelEventNotification(String eventId) async {
    print('[EventsProvider] Canceling notification for event: $eventId');
    
    try {
      await flutterLocalNotificationsPlugin.cancel(eventId.hashCode);
      print('[EventsProvider] Notification canceled successfully');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR canceling notification: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
    }
  }

  Future<void> rescheduleNotifications() async {
    print('[EventsProvider] Rescheduling all notifications. Total events: ${_events.length}');
    
    try {
      for (var event in _events) {
        print('[EventsProvider] Rescheduling notification for event: ${event.id}');
        await scheduleEventNotification(event);
      }
      print('[EventsProvider] All notifications rescheduled successfully');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR rescheduling notifications: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    print('[EventsProvider] Requesting Android notification permissions...');
    
    try {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
              
      if (androidPlugin == null) {
        print('[EventsProvider] Android plugin not available');
        return false;
      }
      
      print('[EventsProvider] Requesting permissions...');
      final granted = await androidPlugin.requestNotificationsPermission();
      print('[EventsProvider] Permissions granted: $granted');
      return granted ?? false;
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR requesting permissions: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Дополнительный метод для полной отладки
  void debugState() {
    print('===== EVENTS PROVIDER DEBUG STATE =====');
    print('Total events: ${_events.length}');
    for (var event in _events) {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final bool isFuture = event.date.isAfter(now);
      final Duration timeUntil = isFuture ? event.date.difference(now) : now.difference(event.date);
      
      print('Event ID: ${event.id}');
      print('Title: ${event.title}');
      print('Date: ${event.date.toIso8601String()}');
      print('Timezone: ${event.date.location.name}');
      print('Event type: ${event.eventType}');
      print('Is future: $isFuture');
      print('Time until: ${timeUntil.inDays}d ${timeUntil.inHours % 24}h ${timeUntil.inMinutes % 60}m ${timeUntil.inSeconds % 60}s');
      print('Notification ID: ${event.hashCode}');
      print('-----------------------------------');
    }
    print('=====================================');
  }
}