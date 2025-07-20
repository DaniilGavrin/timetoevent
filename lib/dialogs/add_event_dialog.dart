import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../providers/events_provider.dart';
import 'package:timetoevent/l10n/app_locale.dart'; // Убедитесь, что путь верный

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  EventType _eventType = EventType.countdown;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _saveEvent() {
    if (_titleController.text.trim().isEmpty) return;

    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final tzDateTime = tz.TZDateTime.from(selectedDateTime, tz.local);

    final event = Event(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      date: tzDateTime,
      eventType: _eventType,
    );

    context.read<EventsProvider>().addEvent(event);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Получаем текущий язык через Flutter Localizations API
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocale.new_event.getString(context),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocale.event_title.getString(context),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 16),
            Divider(),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(AppLocale.date.getString(context)),
              subtitle: Text(
                DateFormat.yMMMMd(languageCode).format(_selectedDate),
              ),
              onTap: _pickDate,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(AppLocale.time.getString(context)),
              subtitle: Text(
                // Форматируем время в зависимости от текущей локали
                DateFormat.Hm().format(DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                )),
              ),
              onTap: _pickTime,
            ),

            ListTile(
              title: Text(AppLocale.event_type.getString(context)),
              trailing: DropdownButton<EventType>(
                value: _eventType,
                onChanged: (value) {
                  setState(() => _eventType = value!);
                },
                items: EventType.values.map((type) {
                  return DropdownMenuItem<EventType>(
                    value: type,
                    child: Text(
                      type == EventType.countdown
                          ? AppLocale.countdown.getString(context)
                          : AppLocale.retro.getString(context),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocale.cancel.getString(context)),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saveEvent,
                  icon: const Icon(Icons.save),
                  label: Text(AppLocale.save.getString(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}