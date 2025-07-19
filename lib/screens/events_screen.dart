import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

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
          /*
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          */
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          final now = tz.TZDateTime.now(tz.local);

          // 1. БУДУЩИЕ СОБЫТИЯ (countdown, дата в будущем)
          final futureEvents = eventsProvider.events
              .where((e) => e.date.isAfter(now) && e.eventType == EventType.countdown)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          // 2. РЕТРО-СОБЫТИЯ (retroactive, всегда в прошлом)
          final retroEvents = eventsProvider.events
              .where((e) => e.eventType == EventType.retroactive)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          // 3. ПРОШЕДШИЕ СОБЫТИЯ (countdown, дата в прошлом)
          final pastEvents = eventsProvider.events
              .where((e) => e.date.isBefore(now) && e.eventType == EventType.countdown)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // 1. БУДУЩИЕ СОБЫТИЯ
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

              // 2. РЕТРО-СОБЫТИЯ
              if (retroEvents.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Ретро события',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...retroEvents.map((event) => _buildEventItem(eventsProvider, event)),
                  ],
                ),

              // 3. ПРОШЕДШИЕ СОБЫТИЯ
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

              // СООБЩЕНИЕ О ПУСТОМ СПИСКЕ
              if (eventsProvider.events.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Нет событий'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _showAddEventDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить событие'),
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
        onTap: () async {
        // Переход к деталям события
        await context.push('/event/${event.id}');
        // Принудительное обновление экрана после возврата
        setState(() {});
      },
        child: EventItem(event: event, isCountdown: true,),
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