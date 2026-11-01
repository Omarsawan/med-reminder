import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../screens/medicine_edit_screen.dart';
import 'common.dart';

const takenColor = Color(0xFF2E7D32);

/// One dose: photo, name, how much, for whom, and a one-tap "Taken" button.
class DoseTile extends StatelessWidget {
  const DoseTile(this.dose, {super.key, this.large = false});

  final Dose dose;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final m = dose.medicine;
    final showPerson = state.people.length > 1;
    final done = !dose.isPending;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDoseSheet(context, dose),
        child: Opacity(
          opacity: done ? 0.7 : 1,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                MedPhoto(m, size: large ? 96 : 72),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        style: (large ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(context.fmt.doseLine(m), style: theme.textTheme.bodyMedium),
                      if (showPerson) ...[
                        const SizedBox(height: 4),
                        PersonChip(state.personById(m.personId)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _DoseAction(dose),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoseAction extends StatelessWidget {
  const _DoseAction(this.dose);

  final Dose dose;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final log = dose.log;
    if (log == null) {
      return FilledButton.tonalIcon(
        onPressed: () => context.read<AppState>().mark(dose, LogStatus.taken),
        icon: const Icon(Icons.check_rounded),
        label: Text(l.taken),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
      );
    }
    final taken = log.status == LogStatus.taken;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          taken ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
          color: taken ? takenColor : Theme.of(context).colorScheme.outline,
          size: 32,
        ),
        Text(
          taken ? l.takenAt(context.fmt.time(log.at)) : l.skipped,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Big view of one dose with all actions.
Future<void> showDoseSheet(BuildContext context, Dose dose) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final state = context.read<AppState>();
      final l = context.l;
      final theme = Theme.of(context);
      final m = dose.medicine;
      final log = dose.log;
      void act(Future<void> Function() f) {
        Navigator.pop(context);
        f();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MedPhoto(m, size: 200),
              const SizedBox(height: 16),
              Text(m.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '${context.fmt.time(dose.at)} · ${context.fmt.doseLine(m)}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              PersonChip(state.personById(m.personId)),
              if (m.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(m.notes, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              if (log == null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => act(() => state.mark(dose, LogStatus.taken)),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l.taken),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => act(() => state.mark(dose, LogStatus.skipped)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: Text(l.skip),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => act(() => state.undo(dose)),
                    icon: const Icon(Icons.undo_rounded),
                    label: Text(l.undo),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MedicineEditScreen(medicine: state.medicineById(m.id))),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.editMedicine),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// All doses due at one time, with a header and an "All taken" button.
class SlotSection extends StatelessWidget {
  const SlotSection({super.key, required this.at, required this.doses, this.large = false});

  final DateTime at;
  final List<Dose> doses;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final pending = doses.where((d) => d.isPending).length;
    final (label, color) = pending == 0
        ? (l.stateDone, takenColor)
        : switch (doses.first.stateAt(now)) {
            DoseState.due => (l.stateDue, theme.colorScheme.primary),
            DoseState.missed => (l.stateMissed, theme.colorScheme.error),
            _ => (l.stateUpcoming, theme.colorScheme.outline),
          };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(
              children: [
                Text(context.fmt.time(at), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
                ),
                const Spacer(),
                if (pending > 1)
                  TextButton.icon(
                    onPressed: () => context.read<AppState>().markSlotTaken(at),
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(l.markAllTaken),
                  ),
              ],
            ),
          ),
          for (final d in doses) DoseTile(d, large: large),
        ],
      ),
    );
  }
}
