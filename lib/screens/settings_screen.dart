import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timetoevent/models/language_options.dart';
import 'package:timetoevent/providers/localization_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../l10n/app_locale.dart';
import 'package:timetoevent/dialogs/language_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTimeZone = 'Europe/Moscow';

  // Список поддерживаемых языков
  final List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: 'en',
      nameKey: AppLocale.english,
      icon: Icons.language,
    ),
    LanguageOption(
      code: 'ru',
      nameKey: AppLocale.russian,
      icon: Icons.translate,
    ),
    // Добавляйте сюда новые языки
  ];

  @override
  void initState() {
    super.initState();
    _loadTimeZone();
  }

  Future<void> _loadTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTimeZone = prefs.getString('time_zone') ?? 'Europe/Moscow';
    });
  }

  Future<void> _navigateToTimeZonePicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TimeZoneSelectionScreen(),
      ),
    );

    if (result == true) {
      _loadTimeZone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.settings.getString(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Карточка для часового пояса
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: _navigateToTimeZonePicker,
              leading: const Icon(Icons.schedule, size: 32),
              title: Text(
                AppLocale.time_zone.getString(context),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _selectedTimeZone,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocale.language.getString(context),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showLanguageDialog(context),
                    child: Text(
                      localizationProvider.languageCode == 'en'
                          ? AppLocale.english.getString(context)
                          : AppLocale.russian.getString(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeZoneSelectionScreen extends StatefulWidget {
  const TimeZoneSelectionScreen({super.key});

  @override
  State<TimeZoneSelectionScreen> createState() => _TimeZoneSelectionScreenState();
}

class _TimeZoneSelectionScreenState extends State<TimeZoneSelectionScreen> {
  List<String> _timeZones = [];
  List<String> _filteredTimeZones = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTimeZones();
  }

  void _loadTimeZones() {
    _timeZones = tz.timeZoneDatabase.locations.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    _filteredTimeZones = _timeZones;
  }

  void _filterTimeZones(String query) {
    setState(() {
      _filteredTimeZones = _timeZones
          .where((tz) => tz.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.select_time_zone.getString(context)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocale.search_time_zones.getString(context),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterTimeZones,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredTimeZones.length,
        itemBuilder: (context, index) {
          final timeZone = _filteredTimeZones[index];
          return ListTile(
            title: Text(timeZone),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('time_zone', timeZone);
              tz.setLocalLocation(tz.getLocation(timeZone));
              Navigator.pop(context, true);
            },
          );
        },
      ),
    );
  }
}