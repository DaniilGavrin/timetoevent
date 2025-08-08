// providers/events_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timetoevent/main.dart';
import 'package:timetoevent/providers/auth_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:uuid/uuid.dart';
import 'package:timetoevent/models/event.dart';
import 'package:timetoevent/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class EventsProvider with ChangeNotifier {
  List<Event> _events = [];
  List<Event> get events => _events;

  // Внутри класса EventsProvider добавьте поле для хранения контекста
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  // Обновите метод syncWithCloud
  Future<void> syncWithCloud() async {
    if (_context == null) {
      print('[EventsProvider] Context is null. Cannot sync with cloud.');
      return;
    }
    
    try {
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      if (authProvider.currentUser != null) {
        print('[EventsProvider] Syncing events with cloud...');
        await authProvider.syncEventsToCloud(this);
        print('[EventsProvider] Events synced with cloud successfully');
      } else {
        print('[EventsProvider] No user logged in. Skipping cloud sync.');
      }
    } catch (e, stackTrace) {
      print('[EventsProvider] ERROR syncing with cloud: $e');
      print('[EventsProvider] Stack trace: $stackTrace');
    }
  }

  EventsProvider() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    print('[EventsProvider] Loading events from SharedPreferences...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      print('[EventsProvider] SharedPreferences instance obtained');
      
      // КЛЮЧЕВОЙ ФИКС: сначала проверяем тип данных
      final dynamic eventData = prefs.get('events');
      
      if (eventData == null) {
        print('[EventsProvider] No events found in SharedPreferences');
        _events = [];
        notifyListeners();
        return;
      }
      
      List<String> eventJsonList;
      
      // Определяем тип данных и обрабатываем соответствующим образом
      if (eventData is List) {
        // Данные хранятся как список строк (новый формат)
        eventJsonList = eventData.cast<String>();
        print('[EventsProvider] Loaded events as List<String>');
      } else if (eventData is String) {
        // Данные хранятся как строка JSON (старый формат)
        print('[EventsProvider] Loaded events as String');
        
        try {
          final List<dynamic> eventsData = json.decode(eventData);
          eventJsonList = eventsData.map((e) => json.encode(e)).toList();
          
          print('[EventsProvider] Converted from old format to new format');
          
          // Пересохраняем в новом формате для будущих загрузок
          await prefs.setStringList('events', eventJsonList);
        } catch (e) {
          print('[EventsProvider] Error converting old format: $e');
          _events = [];
          notifyListeners();
          return;
        }
      } else {
        print('[EventsProvider] Unknown data type for events: ${eventData.runtimeType}');
        _events = [];
        notifyListeners();
        return;
      }
      
      if (eventJsonList.isEmpty) {
        print('[EventsProvider] No events found in SharedPreferences');
        _events = [];
        notifyListeners();
        return;
      }
      
      print('[EventsProvider] Found ${eventJsonList.length} events in SharedPreferences');
      
      // Парсим события
      _events = [];
      for (var json in eventJsonList) {
        try {
          final Map<String, dynamic> data = jsonDecode(json);
          
          // Получаем часовой пояс из данных события или используем Московский по умолчанию
          final String timezone = data['timezone'] ?? 'Europe/Moscow';
          print('[EventsProvider] Event timezone: $timezone');
          
          final tz.Location location = tz.getLocation(timezone);
          
          // ПРАВИЛЬНЫЙ СПОСОБ ПАРСИНГА ДАТЫ С УЧЕТОМ ЧАСОВОГО ПОЯСА
          final tz.TZDateTime date = tz.TZDateTime.parse(location, data['date']);
          
          final tz.TZDateTime? createdAt = data['createdAt'] != null
              ? tz.TZDateTime.parse(location, data['createdAt'])
              : null;
          
          // Создаем событие с учетом нового поля description
          final event = Event(
            id: data['id'],
            title: data['title'],
            description: data['description'] ?? '', // Добавляем поле description с значением по умолчанию
            date: date,
            eventType: EventType.values.byName(data['eventType']),
            createdAt: createdAt,
          );
          
          _events.add(event);
          print('[EventsProvider] Parsed event: ${event.id} - ${event.title}');
        } catch (e, stackTrace) {
          print('[EventsProvider] Error parsing event: $e');
          print('[EventsProvider] Stack trace: $stackTrace');
        }
      }
      
      print('[EventsProvider] Events loaded successfully. Total: ${_events.length}');
      notifyListeners();
      
      // Перезапускаем уведомления
      print('[EventsProvider] Rescheduling notifications...');
      for (var event in _events) {
        await scheduleEventNotification(event);
      }
      print('[EventsProvider] Notifications rescheduled successfully');
    } catch (error, stackTrace) {
      print('[EventsProvider] CRITICAL ERROR loading events: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      _events = [];
      notifyListeners();
    }
  }

  void setEvents(List<Event> events) {
    // Удаляем дубликаты перед установкой
    final uniqueEvents = <String, Event>{};
    for (final event in events) {
      uniqueEvents[event.id] = event;
    }
    
    _events = uniqueEvents.values.toList();
    notifyListeners();
    rescheduleNotifications();
  }

  Future<void> saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = json.encode(_events.map((e) => e.toJson()).toList());
    await prefs.setString('events', eventsJson);

    // Синхронизируем с облаком
    if (_context != null) {
      await syncWithCloud();
    }
  }

  Future<void> addEvent(Event event) async {
    _events.add(event);
    await saveEvents();
    await scheduleEventNotification(event);
    notifyListeners();

    // Синхронизируем с облаком
    if (_context != null) {
      await syncWithCloud();
    }
  }

  Future<void> updateEvent(Event updatedEvent) async {
    print('[EventsProvider] Updating event: ${updatedEvent.id}');
    
    try {
      final index = _events.indexWhere((e) => e.id == updatedEvent.id);
      if (index != -1) {
        print('[EventsProvider] Found event at index $index');
        
        // Сначала отменяем старое уведомление
        await cancelEventNotification(updatedEvent.id);
        
        // Заменяем событие
        _events[index] = updatedEvent;
        
        // Планируем новое уведомление
        await scheduleEventNotification(updatedEvent);
        
        // Сохраняем изменения
        await saveEvents();
        
        // Уведомляем слушателей
        notifyListeners();
        
        print('[EventsProvider] Event updated successfully: ${updatedEvent.id}');
      } else {
        print('[EventsProvider] Event not found: ${updatedEvent.id}');
      }
      // Синхронизируем с облаком
      if (_context != null) {
        await syncWithCloud();
      }
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR updating event: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      rethrow; // Пробрасываем ошибку дальше для обработки в UI
    }
  }

  Future<void> removeEvent(String eventId) async {
    final event = _events.firstWhere((e) => e.id == eventId, orElse: () => null as dynamic);
    if (event != null) {
      await cancelEventNotification(eventId);
      _events.remove(event);
      await saveEvents();
      notifyListeners();
      
      // ИСПОЛЬЗУЕМ ГЛОБАЛЬНЫЙ КОНТЕКСТ
      _syncEventDeletionWithCloud(eventId);
    }
  }

  void _syncEventDeletionWithCloud(String eventId) {
    // Получаем контекст из глобального ключа
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) {
      print('[EventsProvider] Global context is not available. Will retry later.');
      // Можно добавить событие в очередь для последующей синхронизации
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      authProvider.deleteEventFromCloud(eventId).catchError((e) {
        print('[EventsProvider] Failed to delete event from cloud: $e');
        // Можно добавить событие в очередь для повторной синхронизации
      });
    }
  }

  Future<void> scheduleEventNotification(Event event) async {
    try {
      final tz.TZDateTime scheduledDate = event.date;
      final now = tz.TZDateTime.now(tz.local);
      
      if (scheduledDate.isBefore(now)) {
        return; // Не планируем уведомления для прошедших событий
      }
      
      // Настройки для Android
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'event_timer_channel',
        'Event Timer Notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      // Настройки для iOS
      const DarwinNotificationDetails iosPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Настройки для Windows
      final WindowsNotificationDetails windowsPlatformChannelSpecifics =
          const WindowsNotificationDetails();

      // Настройки для Linux
      final LinuxNotificationDetails linuxPlatformChannelSpecifics =
          const LinuxNotificationDetails();

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
        windows: windowsPlatformChannelSpecifics,
        linux: linuxPlatformChannelSpecifics,
      );

      final String payload = jsonEncode(event.toJson());
      
      // ИСПОЛЬЗУЕМ ID СОБЫТИЯ В КАЧЕСТВЕ УНИКАЛЬНОГО ИДЕНТИФИКАТОРА
      // вместо event.hashCode, который меняется при обновлении
      await flutterLocalNotificationsPlugin.zonedSchedule(
        event.id.hashCode, // Используем хеш от ID события как уникальный ID
        'Событие завершено',
        'Ваше событие "${event.title}" завершено.',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      print('[EventsProvider] Notification scheduled for event: ${event.id}');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR scheduling notification: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
      
      if (error is PlatformException) {
        print('[EventsProvider] PlatformException code: ${error.code}');
        print('[EventsProvider] PlatformException message: ${error.message}');
      }
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

  Future<void> cancelEventNotification(String eventId) async {
    try {
      // Отменяем уведомление по ID события
      await flutterLocalNotificationsPlugin.cancel(eventId.hashCode);
      print('[EventsProvider] Notification canceled for event: $eventId');
    } catch (error, stackTrace) {
      print('[EventsProvider] ERROR canceling notification: $error');
      print('[EventsProvider] Stack trace: $stackTrace');
    }
  }

  Future<void> fixDuplicateEvents() async {
    final prefs = await SharedPreferences.getInstance();
    
    // КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: сначала определяем тип данных
    final dynamic eventData = prefs.get('events');
    
    if (eventData == null) {
      print('[EventsProvider FIX] No events found in SharedPreferences');
      return;
    }
    
    List<String> eventJsonList;
    
    // Определяем тип данных и обрабатываем соответствующим образом
    if (eventData is List) {
      // Данные хранятся как список строк (новый формат)
      eventJsonList = eventData.cast<String>();
      print('[EventsProvider] Loaded events as List<String>');
    } else if (eventData is String) {
      // Данные хранятся как строка JSON (старый формат)
      print('[EventsProvider] Loaded events as String');
      
      try {
        final List<dynamic> eventsData = json.decode(eventData);
        eventJsonList = eventsData.map((e) => json.encode(e)).toList();
        
        print('[EventsProvider] Converted from old format to new format');
      } catch (e) {
        print('[EventsProvider] Error converting old format: $e');
        return;
      }
    } else {
      print('[EventsProvider] Unknown data type for events: ${eventData.runtimeType}');
      return;
    }
    
    if (eventJsonList.isEmpty) {
      print('[EventsProvider] No events found in SharedPreferences');
      return;
    }
    
    print('[EventsProvider] Found ${eventJsonList.length} events in SharedPreferences');
    
    // Создаем Map для отслеживания уникальных ID
    final uniqueEvents = <String, String>{};
    
    for (final json in eventJsonList) {
      try {
        final data = jsonDecode(json);
        final id = data['id'];
        
        // Сохраняем только последнее событие с данным ID
        uniqueEvents[id] = json;
      } catch (e) {
        print('[EventsProvider] Error processing event: $e');
      }
    }
    
    // Сохраняем только уникальные события
    final fixedList = uniqueEvents.values.toList();
    
    // ВСЕГДА СОХРАНЯЕМ В НОВОМ ФОРМАТЕ (как список строк)
    await prefs.setStringList('events', fixedList);
    
    print('[EventsProvider] Fixed duplicate events. Original: ${eventJsonList.length}, Fixed: ${fixedList.length}');
  }
}