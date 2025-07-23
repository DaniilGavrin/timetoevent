// event.dart
import 'package:timezone/timezone.dart' as tz;

enum EventType { countdown, retroactive }

class Event {
  final tz.TZDateTime createdAt;
  final String id;
  final String title;
  final tz.TZDateTime date;
  final EventType eventType; // Тип события

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.eventType,
    tz.TZDateTime? createdAt,
  }) : createdAt = createdAt ?? tz.TZDateTime.now(tz.local);

  factory Event.fromJson(Map<String, dynamic> json) {
    final utcDate = DateTime.parse(json['date']);
    final tzDate = tz.TZDateTime.from(utcDate, tz.local);
    final utcCreatedAt = DateTime.parse(json['createdAt']);
    final tzCreatedAt = tz.TZDateTime.from(utcCreatedAt, tz.local);
    return Event(
      id: json['id'],
      title: json['title'],
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
      'date': date.toIso8601String(),
      'eventType': eventType.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  
}