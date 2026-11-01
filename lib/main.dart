import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'logic/env.dart';
import 'state/app_state.dart';
import 'ui/screens/slot_screen.dart';

late final AppState _state;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = await Env.boot(onNotificationResponse: _onNotification);
  _state = AppState(env);
  await _state.load();
  runApp(ChangeNotifierProvider.value(value: _state, child: const MedApp()));

  // Opened by tapping a reminder while the app was closed.
  final launch = await env.reminders.launchResponse();
  if (launch != null) WidgetsBinding.instance.addPostFrameCallback((_) => _onNotification(launch));
  await env.reminders.rescheduleAll();
}

/// A reminder (or one of its buttons) was tapped while the app is running.
Future<void> _onNotification(NotificationResponse r) async {
  if (r.actionId != null) {
    await _state.env.reminders.handleResponse(r);
    await _state.load();
    return;
  }
  final ms = int.tryParse(r.payload ?? '');
  if (ms == null) return;
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => SlotScreen(at: DateTime.fromMillisecondsSinceEpoch(ms))),
  );
}
