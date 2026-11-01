import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../sync/sync_service.dart';
import '../widgets/common.dart';
import 'family_screen.dart';

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

  bool _joining = false;

  /// A second phone joins the family before adding anyone, so people and
  /// medicines come from the family instead of being entered twice.
  Future<void> _join() async {
    final l = context.l;
    final state = context.read<AppState>();
    final sync = context.read<SyncService>();
    final messenger = ScaffoldMessenger.of(context);
    final code = await askFamilyCode(context);
    if (code == null) return;
    setState(() => _joining = true);
    try {
      await sync.joinFamily(code);
      await state.env.reminders.requestPermissions();
      await state.saveSettings(state.settings.copyWith(onboarded: true));
    } on SyncException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.kind == SyncError.badCode ? l.badCode : l.networkError)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.networkError)));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sync = context.watch<SyncService>();
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
            if (sync.available) ...[
              const SizedBox(height: 16),
              _joining
                  ? const Center(child: CircularProgressIndicator())
                  : TextButton.icon(
                      onPressed: _join,
                      icon: const Icon(Icons.family_restroom_rounded),
                      label: Text(l.joinFromWelcome, textAlign: TextAlign.center),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
