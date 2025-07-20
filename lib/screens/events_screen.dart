import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';
import '../providers/events_provider.dart';
import '../widgets/event_item.dart';
import '../dialogs/add_event_dialog.dart';
import 'package:timetoevent/l10n/app_locale.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.app_title.getString(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          final now = tz.TZDateTime.now(tz.local);

          // Фильтрация событий
          final futureEvents = eventsProvider.events
              .where((e) => e.date.isAfter(now) && e.eventType == EventType.countdown)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          final retroEvents = eventsProvider.events
              .where((e) => e.eventType == EventType.retroactive)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final pastEvents = eventsProvider.events
              .where((e) => e.date.isBefore(now) && e.eventType == EventType.countdown)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // БУДУЩИЕ СОБЫТИЯ
              if (futureEvents.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocale.future_events.getString(context),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...futureEvents.map((event) => _buildEventItem(eventsProvider, event)),
                  ],
                ),

              // РЕТРО-СОБЫТИЯ
              if (retroEvents.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocale.retro_events.getString(context),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...retroEvents.map((event) => _buildEventItem(eventsProvider, event)),
                  ],
                ),

              // ПРОШЕДШИЕ СОБЫТИЯ
              if (pastEvents.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocale.past_events.getString(context),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...pastEvents.map((event) => _buildEventItem(eventsProvider, event)),
                  ],
                ),
              if (eventsProvider.events.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Красивая иконка вместо анимации
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Заголовок "Нет событий"
                      Text(
                        AppLocale.no_events.getString(context),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Подсказка пользователю
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          AppLocale.add_event_prompt.getString(context),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                fontSize: 14,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventItem(EventsProvider provider, Event event) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocale.delete_event_title.getString(context)),
            content: Text(
              '${AppLocale.delete_event_content.getString(context)} "${event.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocale.cancel.getString(context)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocale.delete.getString(context)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => provider.removeEvent(event.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () async {
          await context.push('/event/${event.id}');
          setState(() {});
        },
        child: EventItem(event: event, isCountdown: event.eventType == EventType.countdown),
      ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEventDialog(),
    );
  }
}