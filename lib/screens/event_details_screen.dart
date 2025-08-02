// screens/event_details_screen.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';
import '../providers/events_provider.dart';
import 'package:timetoevent/l10n/app_locale.dart';

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
  bool _isFullScreen = false;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _event = context.read<EventsProvider>().events.firstWhere((e) => e.id == widget.eventId);
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }
  
  void _navigateToEditScreen() {
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
    if (mounted) {
        context.go('/');
    }
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

    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    final progress = _calculateProgress(now, totalDuration);
    final percent = (progress * 100).toStringAsFixed(2);

    return GestureDetector(
      onTap: _handleDoubleTap,
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : _buildAppBar(context, theme),
        body: _isFullScreen
            ? _buildFullScreenContent(theme, now, progress, percent, languageCode)
            : _buildNormalContent(theme, now, isFuture, progress, percent, languageCode),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
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
          // Отображение описания
          if (_event.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _event.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_event.description.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                AppLocale.no_description.getString(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          
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
      color: theme.colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Отображение описания в полноэкранном режиме
          if (_event.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                _event.description,
                style: TextStyle(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_event.description.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                AppLocale.no_description.getString(context),
                style: TextStyle(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Таймер
          Text(
            '${_duration.inDays}${AppLocale.days.getString(context)} '
            '${_duration.inHours % 24}${AppLocale.hours.getString(context)} '
            '${_duration.inMinutes % 60}${AppLocale.minutes.getString(context)} '
            '${_duration.inSeconds % 60}${AppLocale.seconds.getString(context)}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
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
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFuture ? theme.colorScheme.primary : theme.colorScheme.error,
                    ),
                  ),
                ),
                Text(
                  '$percent${AppLocale.percent.getString(context)}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}