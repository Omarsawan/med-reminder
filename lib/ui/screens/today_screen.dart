import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/dose_widgets.dart';
import 'medicine_edit_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  String? _personId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = context.l;
    final fmt = context.fmt;
    final theme = Theme.of(context);
    bool forPerson(Medicine m) => _personId == null || m.personId == _personId;

    final doses = state.today.where((d) => forPerson(d.medicine)).toList();
    final slots = SplayTreeMap<DateTime, List<Dose>>();
    for (final d in doses) {
      (slots[d.at] ??= []).add(d);
    }
    final asNeeded = state.medicines.where((m) => m.active && m.isAsNeeded && forPerson(m)).toList();
    final lowStock = state.lowStock.where(forPerson).toList();
    final taken = doses.where((d) => d.log?.status == LogStatus.taken).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.navToday),
            Text(fmt.longDate(DateTime.now()), style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          if (doses.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(child: Text(l.dosesTakenOf(taken, doses.length))),
            ),
        ],
      ),
      floatingActionButton: state.medicines.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MedicineEditScreen(initialPersonId: _personId)),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.addMedicine),
      ),
      body: state.medicines.isEmpty
          ? _Empty(onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineEditScreen())))
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
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
                for (final m in lowStock)
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: Icon(Icons.inventory_2_outlined, color: theme.colorScheme.onTertiaryContainer),
                      title: Text(l.lowStock(m.name, fmt.amount(m.unit, m.stock!))),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MedicineEditScreen(medicine: m)),
                      ),
                    ),
                  ),
                if (slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l.noDosesToday, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                  ),
                for (final e in slots.entries) SlotSection(at: e.key, doses: e.value),
                if (asNeeded.isNotEmpty) ...[
                  SectionTitle(l.asNeededSection),
                  for (final m in asNeeded) _AsNeededTile(m),
                ],
              ],
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_rounded, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(context.l.todayEmptyTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(context.l.todayEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(context.l.addMedicine)),
          ],
        ),
      ),
    );
  }
}

class _AsNeededTile extends StatelessWidget {
  const _AsNeededTile(this.medicine);

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = context.l;
    final fmt = context.fmt;
    final theme = Theme.of(context);
    final m = medicine;
    final last = state.lastAsNeededDose(m.id);
    final todayLogs = state.asNeededToday[m.id] ?? const [];
    final nextAllowed = last?.at.add(Duration(minutes: (m.schedule.minGapHours * 60).round()));
    final tooSoon = nextAllowed != null && DateTime.now().isBefore(nextAllowed);

    final info = <String>[
      fmt.doseLine(m),
      if (last != null) l.lastTaken('${fmt.date(last.at)} ${fmt.time(last.at)}'),
      if (tooSoon) l.nextAllowedAt(fmt.time(nextAllowed)),
    ];

    Future<void> take() async {
      final max = m.schedule.maxPerDay;
      if (tooSoon &&
          !await confirm(context,
              title: l.tooSoonTitle,
              body: l.tooSoonBody(fmt.time(last!.at), fmt.number(m.schedule.minGapHours)),
              action: l.takeAnyway)) {
        return;
      }
      if (max != null &&
          todayLogs.length >= max &&
          context.mounted &&
          !await confirm(context,
              title: l.tooSoonTitle, body: l.maxPerDayBody(todayLogs.length, max), action: l.takeAnyway)) {
        return;
      }
      await state.takeAsNeeded(m);
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            MedPhoto(m, size: 72),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  for (final line in info) Text(line, style: theme.textTheme.bodySmall),
                  if (state.people.length > 1) ...[
                    const SizedBox(height: 4),
                    PersonChip(state.personById(m.personId)),
                  ],
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.tonal(
                  onPressed: take,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: Text(l.takeNow),
                ),
                if (todayLogs.isNotEmpty)
                  TextButton(onPressed: () => state.undoAsNeeded(todayLogs.first), child: Text(l.undo)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
