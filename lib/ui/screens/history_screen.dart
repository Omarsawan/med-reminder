import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/dose_widgets.dart';

/// The last two weeks, day by day: what was taken, skipped or missed.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _personId;
  late Future<List<_Entry>> _entries;
  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    // Reload whenever the app state changes (a dose marked elsewhere).
    _state = state;
    _entries = _load(state);
  }

  Future<List<_Entry>> _load(AppState state) async {
    final now = DateTime.now();
    final from = dateOnly(now).subtract(const Duration(days: 13));
    final doses = await state.env.service.dosesBetween(from, now);
    final logs = await state.env.repo.logsBetween(from, now.add(const Duration(minutes: 1)));
    final scheduledKeys = {for (final d in doses) '${d.medicine.id}|${d.at.millisecondsSinceEpoch}'};
    final entries = <_Entry>[
      for (final d in doses) _Entry(d.medicine, d.at, d.log),
      // As-needed doses and doses of paused medicines only exist as logs.
      for (final log in logs)
        if (!scheduledKeys.contains('${log.medicineId}|${log.scheduledAt.millisecondsSinceEpoch}'))
          if (state.medicineById(log.medicineId) case final m?) _Entry(m, log.scheduledAt, log),
    ];
    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state!;
    final l = context.l;
    final fmt = context.fmt;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navHistory)),
      body: FutureBuilder<List<_Entry>>(
        future: _entries,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snap.data!.where((e) => _personId == null || e.medicine.personId == _personId).toList();
          final days = <DateTime, List<_Entry>>{};
          for (final e in entries) {
            (days[dateOnly(e.at)] ??= []).add(e);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              if (state.people.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(l.everyone),
                        selected: _personId == null,
                        onSelected: (_) => setState(() => _personId = null),
                      ),
                      for (final p in state.people)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: Color(p.color), radius: 6),
                            label: Text(p.name),
                            selected: _personId == p.id,
                            onSelected: (_) => setState(() => _personId = p.id),
                          ),
                        ),
                    ],
                  ),
                ),
              if (days.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.historyEmpty, textAlign: TextAlign.center),
                ),
              for (final MapEntry(key: day, value: dayEntries) in days.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                  child: Row(
                    children: [
                      Text(fmt.date(day), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(l.dosesTakenOf(
                        dayEntries.where((e) => e.log?.status == LogStatus.taken).length,
                        dayEntries.length,
                      )),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      for (final e in dayEntries)
                        ListTile(
                          dense: true,
                          leading: MedPhoto(e.medicine, size: 40),
                          title: Text(e.medicine.name),
                          subtitle: Text(
                            [
                              fmt.time(e.at),
                              if (state.people.length > 1) state.personById(e.medicine.personId)?.name ?? '',
                            ].join(' · '),
                          ),
                          trailing: _status(context, e),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _status(BuildContext context, _Entry e) {
    final l = context.l;
    final theme = Theme.of(context);
    final (icon, color, text) = switch (e.log?.status) {
      LogStatus.taken => (Icons.check_circle_rounded, takenColor, l.takenAt(context.fmt.time(e.log!.at))),
      LogStatus.skipped => (Icons.remove_circle_outline_rounded, theme.colorScheme.outline, l.skipped),
      null => e.at.add(Dose.dueWindow).isAfter(DateTime.now())
          ? (Icons.schedule, theme.colorScheme.primary, l.stateDue)
          : (Icons.cancel_rounded, theme.colorScheme.error, l.stateMissed),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: theme.textTheme.labelMedium?.copyWith(color: color)),
        const SizedBox(width: 6),
        Icon(icon, color: color),
      ],
    );
  }
}

class _Entry {
  _Entry(this.medicine, this.at, this.log);

  final Medicine medicine;
  final DateTime at;
  final DoseLog? log;
}
