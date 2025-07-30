import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timetoevent/l10n/app_locale.dart';
import 'package:timetoevent/models/event.dart';
import 'package:timetoevent/providers/events_provider.dart';

class EventEditScreen extends StatefulWidget {
  final String eventId;
  
  const EventEditScreen({super.key, required this.eventId});

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late Event _originalEvent;
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  EventType _eventType = EventType.countdown;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    final eventsProvider = context.read<EventsProvider>();
    _originalEvent = eventsProvider.events.firstWhere((e) => e.id == widget.eventId);
    
    _titleController = TextEditingController(text: _originalEvent.title);
    _titleFocusNode = FocusNode();
    
    _selectedDate = _originalEvent.date.toLocal();
    _selectedTime = TimeOfDay.fromDateTime(_originalEvent.date.toLocal());
    _eventType = _originalEvent.eventType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  DateTime _getDateTime() {
    final date = _selectedDate ?? DateTime.now();
    final time = _selectedTime ?? TimeOfDay.now();
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.event_title_required.getString(context)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final eventsProvider = context.read<EventsProvider>();
      
      final updatedEvent = Event(
        id: _originalEvent.id,
        title: _titleController.text.trim(),
        date: tz.TZDateTime.from(_getDateTime(), tz.local),
        eventType: _eventType,
        createdAt: _originalEvent.createdAt,
      );
      
      await eventsProvider.updateEvent(updatedEvent);
      
      // Используем GoRouter для возврата на предыдущий экран
      if (mounted) {
        context.go('/event/${updatedEvent.id}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.error_saving_event.getString(context)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.edit_event.getString(context)),
        actions: [
          IconButton(
            icon: Icon(
              _isSaving ? Icons.hourglass_empty : Icons.check,
              color: _isSaving ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
            ),
            onPressed: _isSaving ? null : _saveEvent,
            tooltip: AppLocale.save.getString(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Поле для названия
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              decoration: InputDecoration(
                labelText: AppLocale.event_title.getString(context),
                hintText: AppLocale.enter_event_title.getString(context),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 24),
            
            // Выбор даты и времени
            _buildDateTimeSection(context),
            
            const SizedBox(height: 24),
            
            // Выбор типа события
            _buildEventTypeSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocale.event_date_time.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate != null
                              ? DateFormat('d MMMM y', Localizations.localeOf(context).languageCode)
                                  .format(_selectedDate!)
                              : AppLocale.select_date.getString(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      foregroundColor: theme.colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : AppLocale.select_time.getString(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocale.event_type.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(AppLocale.countdown.getString(context)),
              subtitle: Text(AppLocale.countdown_description.getString(context)),
              leading: Radio<EventType>(
                value: EventType.countdown,
                groupValue: _eventType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _eventType = value;
                    });
                  }
                },
              ),
              onTap: () => setState(() => _eventType = EventType.countdown),
            ),
            ListTile(
              title: Text(AppLocale.retro.getString(context)),
              subtitle: Text(AppLocale.retroactive_description.getString(context)),
              leading: Radio<EventType>(
                value: EventType.retroactive,
                groupValue: _eventType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _eventType = value;
                    });
                  }
                },
              ),
              onTap: () => setState(() => _eventType = EventType.retroactive),
            ),
          ],
        ),
      ),
    );
  }
}