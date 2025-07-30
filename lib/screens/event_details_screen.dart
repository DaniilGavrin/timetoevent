import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';
import '../providers/events_provider.dart';
import 'package:timetoevent/l10n/app_locale.dart'; // Убедитесь, что путь верный

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Event _event;
  late Timer _timer;
  Duration _duration = Duration.zero;
  bool _isFullScreen = false; // Новое состояние
  DateTime? _lastTapTime; // Для обнаружения двойного тапа

  @override
  void initState() {
    super.initState();
    _event = context.read<EventsProvider>().events.firstWhere((e) => e.id == widget.eventId);
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }
  
  void _navigateToEditScreen() {
    // Используем GoRouter для перехода к экрану редактирования
    context.go('/event/${widget.eventId}/edit');
  }

  void _handleDoubleTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      setState(() {
        _isFullScreen = !_isFullScreen;
      });
    }
    _lastTapTime = now;
  }

  void _updateTimer() {
    final now = tz.TZDateTime.now(_event.date.location);
    setState(() {
      _duration = _event.date.isAfter(now)
          ? _event.date.difference(now)
          : now.difference(_event.date);
    });
  }

  void _goBack() {
    // Используем GoRouter для возврата назад
    context.pop();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double _calculateProgress(tz.TZDateTime now, Duration totalDuration) {
    if (totalDuration.inSeconds <= 0) return 0.0;

    final elapsed = _event.eventType == EventType.countdown
        ? now.difference(_event.createdAt).inSeconds
        : now.difference(_event.date).inSeconds;

    final progress = elapsed / totalDuration.inSeconds;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = tz.TZDateTime.now(_event.date.location);
    final isFuture = _event.date.isAfter(now);
    final totalDuration = _event.eventType == EventType.countdown
        ? _event.date.difference(_event.createdAt)
        : now.difference(_event.date);

    // Получаем текущий язык
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    // Рассчитываем проценты
    final progress = _calculateProgress(now, totalDuration);
    final percent = (progress * 100).toStringAsFixed(2); // 49.25%

    return GestureDetector(
      onTap: _handleDoubleTap,
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
                title: Text(_event.title),
                actions: [
                  // Кнопка редактирования в правом верхнем углу
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _navigateToEditScreen,
                    tooltip: AppLocale.edit.getString(context),
                  ),
                ],
              ),
        body: _isFullScreen
            ? _buildFullScreenContent(theme, now, progress, percent, languageCode)
            : _buildNormalContent(theme, now, isFuture, progress, percent, languageCode),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    // Определяем, нужно ли показывать кнопку "назад"
    final bool showBackButton = kIsWeb || 
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    
    return AppBar(
      title: Text(_event.title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: AppLocale.back.getString(context),
            )
          : null,
      actions: [
        // Кнопка редактирования в правом верхнем углу
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _navigateToEditScreen,
          tooltip: AppLocale.edit.getString(context),
        ),
      ],
    );
  }

  Widget _buildNormalContent(ThemeData theme, tz.TZDateTime now, bool isFuture, double progress, String percent, String languageCode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    DateFormat('d MMMM y • HH:mm:ss', languageCode).format(_event.date),
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_duration.inDays}${AppLocale.days.getString(context)} '
                    '${_duration.inHours % 24}${AppLocale.hours.getString(context)} '
                    '${_duration.inMinutes % 60}${AppLocale.minutes.getString(context)} '
                    '${_duration.inSeconds % 60}${AppLocale.seconds.getString(context)}',
                    style: theme.textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: progress,
                          backgroundColor: theme.colorScheme.surface.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFuture ? theme.colorScheme.primary : theme.colorScheme.error,
                          ),
                        ),
                      ),
                      Text(
                        '$percent${AppLocale.percent.getString(context)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          shadows: [Shadow(offset: const Offset(1, 1), color: Colors.black.withOpacity(0.5))],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFuture
                        ? AppLocale.until_event.getString(context)
                        : AppLocale.since_event.getString(context),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenContent(ThemeData theme, tz.TZDateTime now, double progress, String percent, String languageCode) {
    final nowLocal = tz.TZDateTime.now(now.location);
    final isFuture = _event.date.isAfter(nowLocal);

    return Container(
      color: theme.colorScheme.background, // Цвет фона из темы
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Таймер
          Text(
            '${_duration.inDays}${AppLocale.days.getString(context)} '
            '${_duration.inHours % 24}${AppLocale.hours.getString(context)} '
            '${_duration.inMinutes % 60}${AppLocale.minutes.getString(context)} '
            '${_duration.inSeconds % 60}${AppLocale.seconds.getString(context)}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground, // Цвет текста из темы
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Прогресс-бар с процентами
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    minHeight: 24,
                    value: progress,
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.2), // Цвет фона из темы
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFuture ? theme.colorScheme.primary : theme.colorScheme.error, // Цвет из темы
                    ),
                  ),
                ),
                Text(
                  '$percent${AppLocale.percent.getString(context)}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface, // Цвет текста из темы
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        color: theme.colorScheme.onSurface.withOpacity(0.5), // Тень из темы
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Надпись
          Text(
            isFuture
                ? AppLocale.until_event.getString(context)
                : AppLocale.since_event.getString(context),
            style: TextStyle(
              fontSize: 24,
              color: theme.colorScheme.onSurfaceVariant, // Цвет текста из темы
            ),
          ),
        ],
      ),
    );
  }
}