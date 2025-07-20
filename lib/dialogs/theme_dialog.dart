import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:timetoevent/l10n/app_locale.dart';
import 'package:timetoevent/models/theme_options.dart';
import 'package:timetoevent/providers/theme_provider.dart';

void showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
  final currentMode = themeProvider.themeMode;
  final themeOptions = [
    ThemeOption(
      mode: ThemeMode.system,
      name: AppLocale.system.getString(context),
      icon: Icons.brightness_auto,
      color: Colors.grey,
    ),
    ThemeOption(
      mode: ThemeMode.light,
      name: AppLocale.light.getString(context),
      icon: Icons.light_mode,
      color: Colors.yellow,
    ),
    ThemeOption(
      mode: ThemeMode.dark,
      name: AppLocale.dark.getString(context),
      icon: Icons.dark_mode,
      color: Colors.blueGrey,
    ),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Text(
              AppLocale.select_theme.getString(context),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Список тем
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: themeOptions.map((option) {
                final isSelected = option.mode == currentMode;

                return Card(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(option.icon, color: option.color),
                    title: Text(option.name),
                    subtitle: Text(
                      option.mode == ThemeMode.system
                          ? AppLocale.system.getString(context)
                          : option.mode == ThemeMode.light
                              ? AppLocale.light.getString(context)
                              : AppLocale.dark.getString(context),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      themeProvider.setThemeMode(option.mode);
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}