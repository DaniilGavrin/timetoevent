// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTimeZone = 'Europe/Moscow';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: _navigateToTimeZonePicker,
              leading: const Icon(Icons.schedule, size: 32),
              title: const Text(
                'Часовой пояс',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _selectedTimeZone,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
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
        title: const Text('Выбор часового пояса'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск часовых поясов...',
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