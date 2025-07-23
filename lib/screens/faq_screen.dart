import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:timetoevent/l10n/app_locale.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.faq_title.getString(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Описание
            Text(
              AppLocale.faq_description.getString(context),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Вопрос 1
            _buildFaqItem(
              context,
              question: AppLocale.faq_item_1_question.getString(context),
              answer: AppLocale.faq_item_1_answer.getString(context),
              icon: Icons.language,
            ),

            // Вопрос 2
            _buildFaqItem(
              context,
              question: AppLocale.faq_item_2_question.getString(context),
              answer: AppLocale.faq_item_2_answer.getString(context),
              icon: Icons.palette,
            ),

            // Вопрос 3
            _buildFaqItem(
              context,
              question: AppLocale.faq_item_3_question.getString(context),
              answer: AppLocale.faq_item_3_answer.getString(context),
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  // Виджет для одного вопроса-ответа
  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}