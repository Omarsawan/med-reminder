import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/reminders.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'people_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  ReminderHealth? _health;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkHealth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check after returning from the phone's settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _checkHealth();
  }

  Future<void> _checkHealth() async {
    final h = await context.read<AppState>().env.reminders.health();
    if (mounted) setState(() => _health = h);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reminders = state.env.reminders;
    final s = state.settings;
    final l = context.l;
    final theme = Theme.of(context);

    Widget choices<T>(List<(T, String)> options, T selected, ValueChanged<T> onSelected) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in options)
              ChoiceChip(label: Text(label), selected: value == selected, onSelected: (_) => onSelected(value)),
          ],
        );

    // [optional] checks are only needed on some phones, so they show as
    // information rather than an error.
    Widget check(String label, bool? ok, VoidCallback? fix, {bool optional = false}) {
      if (ok == null) return const SizedBox.shrink();
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          ok
              ? Icons.check_circle_rounded
              : optional
                  ? Icons.info_outline_rounded
                  : Icons.error_rounded,
          color: ok
              ? const Color(0xFF2E7D32)
              : optional
                  ? theme.colorScheme.outline
                  : theme.colorScheme.error,
        ),
        title: Text(label),
        trailing: ok || fix == null ? null : FilledButton.tonal(onPressed: fix, child: Text(l.fix)),
      );
    }

    final h = _health;
    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          SectionTitle(l.people),
          Card(
            child: ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: Text(state.people.map((p) => p.name).join(', ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleScreen())),
            ),
          ),
          SectionTitle(l.language),
          choices(
            [('system', l.systemLanguage), ('en', 'English'), ('ar', 'العربية')],
            s.language,
            (v) => state.saveSettings(s.copyWith(language: v)),
          ),
          SectionTitle(l.followUp),
          choices(
            [(0, l.off), for (final m in [5, 10, 15, 30]) (m, l.minutesShort(m))],
            s.followUpMinutes,
            (v) => state.saveSettings(s.copyWith(followUpMinutes: v)),
          ),
          if (s.followUpMinutes > 0) ...[
            SectionTitle(l.followUpCount),
            choices(
              [for (final c in [1, 2, 3, 5]) (c, l.timesCount(c))],
              s.followUpCount,
              (v) => state.saveSettings(s.copyWith(followUpCount: v)),
            ),
          ],
          SectionTitle(l.snoozeFor),
          choices(
            [for (final m in [5, 10, 15, 30, 60]) (m, l.minutesShort(m))],
            s.snoozeMinutes,
            (v) => state.saveSettings(s.copyWith(snoozeMinutes: v)),
          ),
          SectionTitle(l.reminderCheck),
          if (h != null) ...[
            check(l.notificationsAllowed, h.notifications, () async {
              await reminders.requestPermissions();
              await _checkHealth();
            }),
            check(l.exactAlarms, h.exactAlarms, () async {
              await reminders.requestPermissions();
              await _checkHealth();
            }),
            check(l.batteryUnrestricted, h.batteryUnrestricted, reminders.openBatterySettings, optional: true),
          ],
          if (Platform.isAndroid)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(l.batteryHelp, style: theme.textTheme.bodySmall),
            ),
          OutlinedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await reminders.showTest();
              messenger.showSnackBar(SnackBar(content: Text(l.testReminderSent)));
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(l.sendTestReminder),
          ),
        ],
      ),
    );
  }
}
