import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../widgets/common.dart';

/// First launch: who takes medicines, then permission to send reminders.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final state = context.read<AppState>();
    await state.addPerson(name, palette[state.people.length % palette.length]);
    _name.clear();
  }

  Future<void> _continue() async {
    final state = context.read<AppState>();
    if (_name.text.trim().isNotEmpty) await _add();
    if (state.people.isEmpty) return;
    await state.env.reminders.requestPermissions();
    await state.saveSettings(state.settings.copyWith(onboarded: true));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = context.l;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            Icon(Icons.medication_rounded, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l.welcomeTitle, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l.welcomeBody, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(hintText: l.personNameHint, border: const OutlineInputBorder()),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _add,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  child: Text(l.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in state.people)
                  InputChip(
                    avatar: CircleAvatar(backgroundColor: Color(p.color), radius: 7),
                    label: Text(p.name),
                    onDeleted: () => state.deletePerson(p),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            ListenableBuilder(
              listenable: _name,
              builder: (context, _) => FilledButton(
                onPressed: state.people.isNotEmpty || _name.text.trim().isNotEmpty ? _continue : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: Text(l.continueLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
