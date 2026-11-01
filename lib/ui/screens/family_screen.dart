import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../sync/sync_service.dart';
import '../widgets/common.dart';

String syncStatusText(BuildContext context, SyncStatus s) {
  final l = context.l;
  return switch (s) {
    SyncStatus.unavailable => l.syncUnavailable,
    SyncStatus.off => l.syncOff,
    SyncStatus.connecting => l.syncConnecting,
    SyncStatus.synced => l.syncSynced,
    SyncStatus.offline => l.syncOffline,
    SyncStatus.error => l.syncError,
  };
}

/// Asks for a family code; returns it normalized, or null if cancelled or
/// not a full code.
Future<String?> askFamilyCode(BuildContext context) async {
  final l = context.l;
  final controller = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.joinFamily),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 24, letterSpacing: 4),
            decoration: InputDecoration(labelText: l.enterCode, hintText: 'XXXX-XXXX'),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: 12),
          Text(l.joinMergeNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l.join)),
      ],
    ),
  );
  controller.dispose();
  if (code == null) return null;
  final normalized = SyncService.normalizeCode(code);
  return normalized.length == 8 ? normalized : null;
}

/// Create a family code on one phone, join it from the other.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await context.read<AppState>().refresh();
    } on SyncException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.kind == SyncError.badCode ? l.badCode : l.networkError)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.networkError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = await askFamilyCode(context);
    if (!mounted || code == null) return;
    final sync = context.read<SyncService>();
    await _run(() => sync.joinFamily(code));
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final l = context.l;
    final theme = Theme.of(context);

    final Widget body;
    if (!sync.available) {
      body = Text(l.syncUnavailable, style: theme.textTheme.bodyLarge);
    } else if (!sync.joined) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.family_restroom_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(l.familyIntro, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(() => sync.createFamily()),
            icon: const Icon(Icons.add_link_rounded),
            label: Text(l.createFamily),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _join,
            icon: const Icon(Icons.login_rounded),
            label: Text(l.joinFamily),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        ],
      );
    } else {
      final code = SyncService.displayCode(sync.joinCode ?? '');
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.familyCode, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Codes are Latin letters and digits: keep them left-to-right in Arabic too.
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: SelectableText(
                      code,
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 4),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.codeCopied)));
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(l.copy),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(l.familyCodeHelp, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(_statusIcon(sync.status), color: _statusColor(context, sync.status)),
            title: Text(syncStatusText(context, sync.status)),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () async {
              if (await confirm(context, title: l.leaveFamily, body: l.leaveFamilyBody, action: l.leaveFamily)) {
                await sync.leaveFamily();
              }
            },
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: Text(l.leaveFamily),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.familySharing)),
      body: ListView(padding: const EdgeInsets.all(24), children: [body]),
    );
  }
}

IconData _statusIcon(SyncStatus s) => switch (s) {
      SyncStatus.synced => Icons.cloud_done_rounded,
      SyncStatus.offline => Icons.cloud_off_rounded,
      SyncStatus.error => Icons.sync_problem_rounded,
      _ => Icons.cloud_sync_rounded,
    };

Color _statusColor(BuildContext context, SyncStatus s) => switch (s) {
      SyncStatus.synced => const Color(0xFF2E7D32),
      SyncStatus.error => Theme.of(context).colorScheme.error,
      _ => Theme.of(context).colorScheme.outline,
    };

/// Small status icon for the Settings row.
Widget syncStatusIcon(BuildContext context, SyncStatus s) =>
    Icon(_statusIcon(s), color: _statusColor(context, s));
