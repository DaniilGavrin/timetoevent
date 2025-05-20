import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class EventItem extends StatelessWidget {
  final Event event;

  const EventItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.date.isBefore(now);

    return Card(
      margin: const EdgeInsets.all(8),
      color: isPast
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isPast
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                isPast ? Icons.warning : Icons.timer,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d MMM y • HH:mm').format(event.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.notifications_active,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}