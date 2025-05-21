import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFuture = _event.date.isAfter(DateTime.now());

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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: isFuture
                            ? 1.0 -
                            (_duration.inSeconds /
                                _event.date.difference(DateTime.now()).inSeconds)
                            : 1.0,
                        backgroundColor: theme.colorScheme.surface.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFuture
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
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
