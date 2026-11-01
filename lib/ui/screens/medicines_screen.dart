import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/dose_widgets.dart';
import 'medicine_edit_screen.dart';

/// All medicines, split by whether they're due today, so a monthly injection
/// doesn't sit among the daily pills looking like it's due.
class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  String? _personId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = context.l;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final dosesToday = <String, List<Dose>>{};
    for (final d in state.today) {
      (dosesToday[d.medicine.id] ??= []).add(d);
    }
    final due = <Medicine>[];
    final asNeeded = <Medicine>[];
    final notDue = <Medicine>[];
    final inactive = <Medicine>[];
    for (final m in state.medicines.where((m) => _personId == null || m.personId == _personId)) {
      if (!m.active || m.schedule.isFinished(now)) {
        inactive.add(m);
      } else if (m.isAsNeeded) {
        asNeeded.add(m);
      } else if (dosesToday.containsKey(m.id)) {
        due.add(m);
      } else {
        notDue.add(m);
      }
    }
    // Soonest first, so "next week" sits above "next month".
    final nextDose = {for (final m in notDue) m.id: m.schedule.nextAfter(now)};
    notDue.sort((a, b) => (nextDose[a.id] ?? DateTime(9999)).compareTo(nextDose[b.id] ?? DateTime(9999)));
    // Due today in order of the first dose still waiting.
    DateTime firstPending(Medicine m) =>
        dosesToday[m.id]!.where((d) => d.isPending).map((d) => d.at).firstOrNull ?? DateTime(9999);
    due.sort((a, b) => firstPending(a).compareTo(firstPending(b)));

    Widget section(String title, List<Medicine> meds, Widget Function(Medicine) details, {bool muted = false}) {
      if (meds.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle('$title (${meds.length})'),
          for (final m in meds) _MedicineCard(m, details: details(m), muted: muted),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.navMedicines)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicineEditScreen(initialPersonId: _personId)),
        ),
        tooltip: l.addMedicine,
        child: const Icon(Icons.add),
      ),
      body: state.medicines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l.medicinesEmpty, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
              children: [
                PersonFilter(selected: _personId, onChanged: (id) => setState(() => _personId = id)),
                section(l.dueToday, due, (m) => _TodayDoses(dosesToday[m.id]!)),
                section(l.asNeededSection, asNeeded, (m) => const SizedBox.shrink()),
                section(
                  l.notDueToday,
                  notDue,
                  (m) => nextDose[m.id] == null
                      ? const SizedBox.shrink()
                      : Text(
                          l.nextDue(context.fmt.when(nextDose[m.id]!, now)),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  muted: true,
                ),
                section(
                  l.pausedOrFinished,
                  inactive,
                  (m) => Text(m.active ? l.finished : l.paused),
                  muted: true,
                ),
              ],
            ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard(this.medicine, {required this.details, this.muted = false});

  final Medicine medicine;
  final Widget details;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fmt = context.fmt;
    final theme = Theme.of(context);
    final m = medicine;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: muted ? theme.colorScheme.surfaceContainerLow : null,
      elevation: muted ? 0 : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicineEditScreen(medicine: m)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(opacity: muted ? 0.55 : 1, child: MedPhoto(m, size: 56)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: muted ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                    Text(
                      '${fmt.doseLine(m)} · ${fmt.schedule(m, DateTime.now())}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (m.stock != null)
                      Text(
                        context.l.leftCount(fmt.number(m.stock!)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: m.isLowStock ? theme.colorScheme.error : null,
                        ),
                      ),
                    const SizedBox(height: 4),
                    details,
                    if (state.people.length > 1) ...[
                      const SizedBox(height: 4),
                      PersonChip(state.personById(m.personId)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today's times for one medicine, each marked taken, skipped or waiting.
class _TodayDoses extends StatelessWidget {
  const _TodayDoses(this.doses);

  final List<Dose> doses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final d in doses)
          Builder(builder: (context) {
            final state = d.stateAt(now);
            final (icon, color) = switch (state) {
              DoseState.taken => (Icons.check_circle_rounded, takenColor),
              DoseState.skipped => (Icons.remove_circle_outline_rounded, theme.colorScheme.outline),
              DoseState.missed => (Icons.error_outline_rounded, theme.colorScheme.error),
              DoseState.due => (Icons.notifications_active_rounded, theme.colorScheme.primary),
              DoseState.upcoming => (Icons.schedule_rounded, theme.colorScheme.primary),
            };
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(context.fmt.time(d.at), style: theme.textTheme.labelMedium?.copyWith(color: color)),
                ],
              ),
            );
          }),
      ],
    );
  }
}
