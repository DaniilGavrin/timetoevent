import 'package:timezone/timezone.dart' as tz;

class Event {
  final String id;
  final String title;
  final DateTime date;

  Event({
    required this.id,
    required this.title,
    required this.date,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
    };
  }
}