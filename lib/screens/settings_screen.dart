import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timetoevent/providers/localization_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import '../l10n/app_locale.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTimeZone = 'Europe/Moscow';
  String _selectedLanguage = 'ru'; // Текущий язык

  @override
  void initState() {
    super.initState();
    _loadTimeZone();
    _loadLanguage(); // Загрузка сохраненного языка
  }

  Future<void> _loadTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTimeZone = prefs.getString('time_zone') ?? 'Europe/Moscow';
    });
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'ru';
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
        title: Text(AppLocale.settings.getString(context)), // Используем getString
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
                AppLocale.time_zone.getString(context), // Используем getString
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _selectedTimeZone,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),

          // Карточка для смены языка
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.language, size: 32),
              title: Text(
                AppLocale.language.getString(context),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                localizationProvider.languageCode == 'en' ? 'English' : 'Русский',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: DropdownButton<String>(
                value: localizationProvider.languageCode,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    localizationProvider.setLanguage(newValue);
                  }
                },
                items: <String>['en', 'ru']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'en' ? 'English' : 'Русский',
                    ),
                  );
                }).toList(),
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