import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';

class EventItem extends StatefulWidget {
  final Event event;
  final bool isCountdown;

  const EventItem({super.key, required this.event, required this.isCountdown});

  @override
  State<EventItem> createState() => _EventItemState();
}

class _EventItemState extends State<EventItem> {
  late Timer _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startProgressAnimation();
  }

  void _startProgressAnimation() {
    // Обновляем прогресс каждые 5 секунд
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = tz.TZDateTime.now(widget.event.date.location);
      final totalDuration = widget.event.date.difference(widget.event.createdAt);
      final elapsed = now.difference(widget.event.createdAt).inSeconds;
      final progress = totalDuration.inSeconds <= 0
          ? 0.0
          : (elapsed / totalDuration.inSeconds).clamp(0.0, 1.0);
      setState(() {
        _progress = progress;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isPast = widget.event.date.isBefore(tz.TZDateTime.now(widget.event.date.location));
  final now = tz.TZDateTime.now(widget.event.date.location);
  final totalDuration = widget.event.date.difference(widget.event.createdAt);
  final elapsed = now.difference(widget.event.createdAt).inSeconds;
  final progress = totalDuration.inSeconds <= 0
      ? 0.0
      : (elapsed / totalDuration.inSeconds).clamp(0.0, 1.0);

  return Card(
    margin: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Цветовая полоса
          Container(
            width: 8,
            decoration: BoxDecoration(
              color: isPast
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          // Основная информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isPast
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isPast ? Icons.warning : Icons.timer,
                      color: isPast
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM y • HH:mm').format(widget.event.date),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // Прогресс-бар под датой
                if (widget.event.eventType == EventType.countdown && !isPast)
                  const SizedBox(height: 8),
                if (widget.event.eventType == EventType.countdown && !isPast)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress,
                      backgroundColor: theme.colorScheme.surface.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Иконка уведомления
          Icon(
            Icons.notifications_active,
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    ),
  );
}
}