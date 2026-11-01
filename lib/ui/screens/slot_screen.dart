import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/dose_widgets.dart';

/// Opened by tapping a reminder: just the doses due at that time, large.
class SlotScreen extends StatelessWidget {
  const SlotScreen({super.key, required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = context.l;
    final theme = Theme.of(context);
    // Today's list covers most taps; older reminders fall back to a lookup.
    final fromToday = state.today.where((d) => d.at == at).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.fmt.time(at))),
      body: FutureBuilder<List<Dose>>(
        future: fromToday.isNotEmpty
            ? Future.value(fromToday)
            : state.env.service.dosesBetween(at, at.add(const Duration(minutes: 1))),
        builder: (context, snap) {
          final doses = snap.data ?? const <Dose>[];
          final allDone = doses.isNotEmpty && doses.every((d) => !d.isPending);
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (allDone)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: takenColor, size: 56),
                      const SizedBox(height: 8),
                      Text(l.allDone, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              SlotSection(at: at, doses: doses, large: true),
            ],
          );
        },
      ),
    );
  }
}
