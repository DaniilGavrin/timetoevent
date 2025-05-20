import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/events_provider.dart';

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
    final isFuture = _event.date.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(_event.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat('d MMM y • HH:mm:ss').format(_event.date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              '${_duration.inDays}д ${_duration.inHours % 24}ч ${_duration.inMinutes % 60}м ${_duration.inSeconds % 60}с',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _event.date.isAfter(DateTime.now())
                  ? _duration.inSeconds / _event.date.difference(DateTime.now()).inSeconds
                  : 1.0,
              color: isFuture ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}