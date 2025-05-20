import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../providers/events_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/event_item.dart';
import '../dialogs/add_event_dialog.dart';

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
        title: const Text('Event Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rate_sharp),
            onPressed: () => context.push('/premium'),
          ),
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
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
          final now = DateTime.now();
          final futureEvents = eventsProvider.events
              .where((e) => e.date.isAfter(now))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          final pastEvents = eventsProvider.events
              .where((e) => e.date.isBefore(now))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (futureEvents.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Будущие события',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...futureEvents.map((event) => _buildEventItem(eventsProvider, event)),
                  ],
                ),
              if (pastEvents.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Прошедшие события',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...pastEvents.map((event) => _buildEventItem(eventsProvider, event)),
                  ],
                ),
              if (eventsProvider.events.isEmpty)
                const Center(child: Text('Нет событий')),
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
            title: const Text('Удалить событие?'),
            content: Text('Удалить "${event.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Удалить'),
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
        onTap: () => context.push('/event/${event.id}'),
        child: EventItem(event: event),
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