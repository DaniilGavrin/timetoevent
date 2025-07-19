import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/event.dart';
import '../providers/events_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Event _event;
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    initializeDateFormatting('ru', null);
    super.initState();
    _event = context.read<EventsProvider>().events.firstWhere((e) => e.id == widget.eventId);
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    final now = DateTime.now();
    setState(() {
      _duration = _event.date.isAfter(now)
          ? _event.date.difference(now)
          : now.difference(_event.date);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double _calculateProgress(tz.TZDateTime now, Duration totalDuration) {
    if (totalDuration.inSeconds <= 0) return 0.0;

    final elapsed = _event.eventType == EventType.countdown
        ? now.difference(_event.createdAt).inSeconds
        : now.difference(_event.date).inSeconds;

    final progress = elapsed / totalDuration.inSeconds;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = tz.TZDateTime.now(_event.date.location);
    final isFuture = _event.date.isAfter(now);
    final totalDuration = _event.eventType == EventType.countdown
        ? _event.date.difference(_event.createdAt)
        : now.difference(_event.date);

    // Рассчитываем проценты
    final progress = _calculateProgress(now, totalDuration);
    final percent = (progress * 100).toStringAsFixed(2); // 49.25%

    return Scaffold(
      appBar: AppBar(
        title: Text(_event.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      DateFormat('d MMMM y • HH:mm:ss', 'ru').format(_event.date),
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_duration.inDays}д ${_duration.inHours % 24}ч ${_duration.inMinutes % 60}м ${_duration.inSeconds % 60}с',
                      style: theme.textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Прогресс-бар с процентами
                    if (_event.eventType != EventType.retroactive && 
                        _event.date.isAfter(now))
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Прогресс-бар
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              minHeight: 12,
                              value: progress,
                              backgroundColor: theme.colorScheme.surface.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isFuture
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ),
                          
                          // Текст с процентами
                          Text(
                            '$percent%',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 8),
                    Text(
                      isFuture ? 'До события' : 'С момента события',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}