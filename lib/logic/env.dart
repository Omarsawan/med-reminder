import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/photo_store.dart';
import '../data/repository.dart';
import 'med_service.dart';
import 'reminders.dart';

/// Everything the app needs, set up the same way for the UI and for
/// notification buttons pressed while the app is closed.
class Env {
  Env._(this.repo, this.photos, this.service, this.reminders);

  final Repository repo;
  final PhotoStore photos;
  final MedService service;
  final Reminders reminders;

  static Future<Env> boot({void Function(NotificationResponse)? onNotificationResponse}) async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Unknown zone name: times are converted as absolute instants anyway.
    }
    await initializeDateFormatting();

    final repo = await Repository.open();
    final photos = await PhotoStore.open();
    final service = MedService(repo);
    final reminders = Reminders(service, photos);
    await reminders.initialize(onResponse: onNotificationResponse);
    return Env._(repo, photos, service, reminders);
  }
}
