import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:provider/provider.dart';
import 'package:timetoevent/l10n/app_locale.dart';
import 'package:timetoevent/models/language_options.dart';
import 'package:timetoevent/providers/localization_provider.dart';

void showLanguageDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const LanguageSelectionSheet(),
  );
}

class LanguageSelectionSheet extends StatefulWidget {
  const LanguageSelectionSheet({super.key});

  @override
  State<LanguageSelectionSheet> createState() => _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<LanguageSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<LanguageOption> _filteredLanguages;

  @override
  void initState() {
    super.initState();
    _filteredLanguages = supportedLanguages;
  }

  void _filterLanguages(String query) {
    setState(() {
      _filteredLanguages = supportedLanguages
          .where((lang) =>
              lang.nameKey.getString(context).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Поле поиска
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: AppLocale.search_language.getString(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _filterLanguages,
          ),
          const SizedBox(height: 16),

          // Список языков
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredLanguages.length,
              itemBuilder: (context, index) {
                final lang = _filteredLanguages[index];
                final isSelected = lang.code == Provider.of<LocalizationProvider>(context).languageCode;

                return ListTile(
                  leading: Icon(lang.icon),
                  title: Text(lang.nameKey.getString(context)),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    Provider.of<LocalizationProvider>(context, listen: false).setLanguage(lang.code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

