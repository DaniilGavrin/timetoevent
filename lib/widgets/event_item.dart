import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

// event_item.dart
class EventItem extends StatelessWidget {
  final Event event;
  final bool isCountdown;

  const EventItem({super.key, required this.event, required this.isCountdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = event.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
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
                        DateFormat('d MMM y • HH:mm').format(event.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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