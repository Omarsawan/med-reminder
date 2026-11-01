import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

/// Add a person, or edit [existing]. Returns the saved person.
Future<Person?> showPersonDialog(BuildContext context, {Person? existing}) {
  final state = context.read<AppState>();
  final name = TextEditingController(text: existing?.name ?? '');
  var color = existing?.color ?? palette[state.people.length % palette.length];
  return showDialog<Person>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l = context.l;
        Future<void> save() async {
          if (name.text.trim().isEmpty) return;
          final navigator = Navigator.of(context);
          final Person saved;
          if (existing == null) {
            saved = await state.addPerson(name.text, color);
          } else {
            saved = existing.copyWith(name: name.text.trim(), color: color);
            await state.savePerson(saved);
          }
          navigator.pop(saved);
        }

        return AlertDialog(
          title: Text(existing == null ? l.addPerson : l.edit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l.personName, hintText: l.personNameHint),
                  onSubmitted: (_) => save(),
                ),
                const SizedBox(height: 16),
                ColorPicker(value: color, onChanged: (c) => setState(() => color = c!)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            FilledButton(onPressed: save, child: Text(l.save)),
          ],
        );
      },
    ),
  );
}

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.people)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPersonDialog(context),
        tooltip: l.addPerson,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: ListView(
        children: [
          for (final p in state.people)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(p.color),
                child: Text(
                  p.name.isEmpty ? '?' : String.fromCharCode(p.name.runes.first).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(p.name),
              subtitle: Text('${state.medicines.where((m) => m.personId == p.id).length} · ${l.navMedicines}'),
              onTap: () => showPersonDialog(context, existing: p),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l.delete,
                onPressed: () async {
                  if (state.medicines.any((m) => m.personId == p.id)) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l.deletePersonBlocked(p.name))));
                    return;
                  }
                  if (await confirm(context, title: l.deleteTitle(p.name), action: l.delete)) {
                    await state.deletePerson(p);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
