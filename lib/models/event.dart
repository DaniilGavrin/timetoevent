// models/event.dart
import 'package:timezone/timezone.dart' as tz;

enum EventType { countdown, retroactive }

class Event {
  final tz.TZDateTime createdAt;
  final String id;
  final String title;
  final String description; // Новое поле
  final tz.TZDateTime date;
  final EventType eventType;

  Event({
    required this.id,
    required this.title,
    required this.description, // Добавляем в конструктор
    required this.date,
    required this.eventType,
    tz.TZDateTime? createdAt,
  }) : createdAt = createdAt ?? tz.TZDateTime.now(tz.local);

  factory Event.fromJson(Map<String, dynamic> json) {
    final utcDate = DateTime.parse(json['date']);
    final tzDate = tz.TZDateTime.from(utcDate, tz.local);
    final utcCreatedAt = DateTime.parse(json['createdAt']);
    final tzCreatedAt = tz.TZDateTime.from(utcCreatedAt, tz.local);
    
    // Обеспечиваем совместимость со старыми данными
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '', // Значение по умолчанию для старых событий
      date: tzDate,
      eventType: json['eventType'] == 'retroactive'
          ? EventType.retroactive
          : EventType.countdown,
      createdAt: tzCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description, // Сохраняем описание
      'date': date.toIso8601String(),
      'eventType': eventType.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Добавляем метод copyWith для удобства обновления
  Event copyWith({
    String? id,
    String? title,
    String? description,
    tz.TZDateTime? date,
    EventType? eventType,
    tz.TZDateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      eventType: eventType ?? this.eventType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}