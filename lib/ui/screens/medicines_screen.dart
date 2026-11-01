import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'medicine_edit_screen.dart';

class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = context.l;
    final fmt = context.fmt;
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l.navMedicines)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineEditScreen())),
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
                for (final p in state.people)
                  if (state.medicines.any((m) => m.personId == p.id)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                      child: PersonChip(p),
                    ),
                    for (final m in state.medicines.where((m) => m.personId == p.id))
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          leading: Opacity(opacity: m.active ? 1 : 0.4, child: MedPhoto(m, size: 56)),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmt.doseLine(m)),
                              Text(
                                !m.active
                                    ? l.paused
                                    : m.schedule.isFinished(now)
                                        ? l.finished
                                        : fmt.schedule(m, now),
                              ),
                              if (m.stock != null)
                                Text(
                                  l.leftCount(fmt.number(m.stock!)),
                                  style: TextStyle(color: m.isLowStock ? theme.colorScheme.error : null),
                                ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MedicineEditScreen(medicine: m)),
                          ),
                        ),
                      ),
                  ],
              ],
            ),
    );
  }
}
