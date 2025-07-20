import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:timetoevent/l10n/app_locale.dart';
import 'package:timetoevent/providers/SettingsProvider.dart';

void showIntervalDialog(BuildContext context, SettingsProvider settingsProvider) {
  final TextEditingController controller = TextEditingController(
    text: settingsProvider.updateInterval.toString(),
  );

  int currentValue = settingsProvider.updateInterval;

  showGeneralDialog(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(AppLocale.update_interval.getString(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Быстрые значения (Dropdown)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Быстрые значения:"),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: currentValue,
                      onChanged: (value) {
                        setStateDialog(() {
                          currentValue = value!;
                          controller.text = value.toString();
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("1 сек")),
                        DropdownMenuItem(value: 5, child: Text("5 сек")),
                        DropdownMenuItem(value: 10, child: Text("10 сек")),
                        DropdownMenuItem(value: 30, child: Text("30 сек")),
                        DropdownMenuItem(value: 60, child: Text("1 мин")),
                        DropdownMenuItem(value: 300, child: Text("5 мин")),
                        DropdownMenuItem(value: 600, child: Text("10 мин")),
                        DropdownMenuItem(value: 1600, child: Text("1600 сек")),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Ручной ввод
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocale.update_interval_seconds.getString(context),
                    hintText: "1-1600",
                  ),
                  onChanged: (text) {
                    final int? parsedValue = int.tryParse(text);
                    if (parsedValue != null && parsedValue >= 1 && parsedValue <= 1600) {
                      currentValue = parsedValue;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(AppLocale.cancel.getString(context)),
              ),
              TextButton(
                onPressed: () {
                  int? input = int.tryParse(controller.text);
                  if (input != null && input >= 1 && input <= 1600) {
                    settingsProvider.setUpdateInterval(input);
                  } else {
                    settingsProvider.setUpdateInterval(currentValue);
                  }
                  Navigator.of(context).pop();
                },
                child: Text(AppLocale.save.getString(context)),
              ),
            ],
          );
        },
      );
    },
  );
}