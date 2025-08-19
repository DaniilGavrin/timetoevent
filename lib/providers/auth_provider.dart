import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timetoevent/models/event.dart';
import 'package:timetoevent/providers/events_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  // Добавляем ссылку на EventsProvider
  EventsProvider? _eventsProvider;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null && _eventsProvider != null) {
        syncEventsFromCloud(_eventsProvider!);
      }
      notifyListeners();
    });
  }

  // Метод для установки EventsProvider
  void setEventsProvider(EventsProvider eventsProvider) {
    _eventsProvider = eventsProvider;
  }

  Future<void> signInWithGoogle() async {
    try {
      // Создаем Google провайдер
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Добавляем необходимые scope
      googleProvider.addScope('email');
      googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
      
      // Для веба используем signInWithPopup
      if (kIsWeb) {
        await _auth.signInWithPopup(googleProvider);
      } 
      // Для мобильных платформ используем signInWithProvider
      else {
        await _auth.signInWithProvider(googleProvider);
      }
      
      // После входа синхронизируем данные
      if (_eventsProvider != null) {
        await syncEventsFromCloud(_eventsProvider!);
      }
    } catch (e) {
      print('[AuthProvider] Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('[AuthProvider] Error signing out: $e');
      rethrow;
    }
  }

  Future<void> syncEventsFromCloud(EventsProvider eventsProvider) async {
    if (currentUser == null || _isSyncing) return;
    
    try {
      _isSyncing = true;
      notifyListeners();

      await eventsProvider.loadEvents();

      print('[AuthProvider] Starting cloud sync...');
      print('[AuthProvider] Current user: ${currentUser!.uid}');
      
      // Загружаем события из облака
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('events')
          .get();

      print('[AuthProvider] Cloud events count: ${snapshot.size}');
      
      final cloudEvents = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Преобразуем даты из timestamp
        final date = tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.getLocation(data['timezone'] ?? 'Europe/Moscow'),
          data['date'].toDate().millisecondsSinceEpoch,
        );
        
        final createdAt = data['createdAt'] != null
            ? tz.TZDateTime.fromMillisecondsSinceEpoch(
                tz.getLocation(data['timezone'] ?? 'Europe/Moscow'),
                data['createdAt'].toDate().millisecondsSinceEpoch,
              )
            : null;
        
        return Event(
          id: doc.id,
          title: data['title'],
          description: data['description'] ?? '',
          date: date,
          eventType: EventType.values.byName(data['eventType']),
          createdAt: createdAt,
        );
      }).toList();
      
      // Сравниваем и объединяем события
      final localEvents = List<Event>.from(eventsProvider.events);
      final allEvents = _mergeEvents(localEvents, cloudEvents);

      print('[AuthProvider] Merged events count: ${allEvents.length}');
      
      // КРИТИЧЕСКИ ВАЖНО: ЗАМЕНЯЕМ ВСЕ СОБЫТИЯ ЗА ОДИН РАЗ
      eventsProvider.setEvents(allEvents);
      
      print('[AuthProvider] Events synchronized from cloud. Total: ${allEvents.length}');
    } catch (e) {
      print('[AuthProvider] Error syncing events from cloud: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> deleteEventFromCloud(String eventId) async {
    if (currentUser == null) return;
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      final eventRef = userRef.collection('events').doc(eventId);
      
      await eventRef.delete();
      print('[AuthProvider] Event deleted from cloud: $eventId');
    } catch (e) {
      print('[AuthProvider] Error deleting event from cloud: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncEventsToCloud(EventsProvider eventsProvider) async {
    if (currentUser == null) return;
    
    try {
      _isSyncing = true;
      notifyListeners();
      
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      
      // Удаляем все существующие события перед синхронизацией
      final snapshot = await userRef.collection('events').get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Добавляем все события
      for (final event in eventsProvider.events) {
        final eventRef = userRef.collection('events').doc(event.id);
        batch.set(eventRef, {
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'date': Timestamp.fromDate(event.date.toUtc()),
          // ignore: unnecessary_null_comparison
          'createdAt': event.createdAt != null 
              ? Timestamp.fromDate(event.createdAt!.toUtc()) 
              : null,
          'eventType': event.eventType.name,
          'timezone': 'Europe/Moscow',
        });
      }
      
      await batch.commit();
      print('[AuthProvider] Events synchronized to cloud. Total: ${eventsProvider.events.length}');
    } catch (e) {
      print('[AuthProvider] Error syncing events to cloud: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  List<Event> _mergeEvents(List<Event> localEvents, List<Event> cloudEvents) {
    final Map<String, Event> eventMap = {};
    
    // Сначала добавляем локальные события
    for (final event in localEvents) {
      eventMap[event.id] = event;
    }
    
    // Затем обрабатываем облачные события
    for (final event in cloudEvents) {
      if (eventMap.containsKey(event.id)) {
        final localEvent = eventMap[event.id]!;
        
        // Определяем, какое событие новее
        bool isCloudEventNewer = false;
        
        // Сравниваем по времени создания
        // ignore: unnecessary_null_comparison
        if (event.createdAt != null && localEvent.createdAt != null) {
          isCloudEventNewer = event.createdAt!.isAfter(localEvent.createdAt!);
        } 
        // Если время создания не задано, сравниваем по дате события
        else {
          isCloudEventNewer = event.date.isAfter(localEvent.date);
        }
        
        // Если событие из облака новее, заменяем
        if (isCloudEventNewer) {
          eventMap[event.id] = event;
        }
      } else {
        // Если события нет локально, добавляем его
        eventMap[event.id] = event;
      }
    }
    
    return eventMap.values.toList();
  }
}