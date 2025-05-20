import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../providers/events_provider.dart';

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить событие'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Название события'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickDate,
            child: Text('Выбрать дату: ${DateFormat.yMd().format(_selectedDate)}'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveEvent,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) return;
    final event = Event(
      id: uuid.v4(),
      title: _titleController.text,
      date: _selectedDate,
    );
    context.read<EventsProvider>().addEvent(event);
    Navigator.pop(context);
  }
}