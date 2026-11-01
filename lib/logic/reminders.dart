import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Person;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/photo_store.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'env.dart';
import 'format.dart';
import 'med_service.dart';
import 'slot_image.dart';

const actionTaken = 'taken';
const actionSnooze = 'snooze';
const _channelId = 'doses';
const _iosCategory = 'dose';
const _openAppId = 1;
const _testId = 2;

/// iOS keeps at most 64 pending notifications; stay under it. Android has no
/// hard limit but some phones cap alarms at 500.
int get _budget => Platform.isIOS ? 60 : 300;

/// Runs when a notification button (Taken / Snooze) is pressed while the app
/// is closed. The OS starts a short-lived Dart isolate just for this.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final env = await Env.boot();
  await env.reminders.handleResponse(response);
}

class ReminderHealth {
  const ReminderHealth({required this.notifications, this.exactAlarms, this.batteryUnrestricted});

  final bool notifications;

  /// Android only.
  final bool? exactAlarms;
  final bool? batteryUnrestricted;
}

/// Hands every upcoming dose to the operating system's scheduler. Nothing runs
/// in the background: the schedule is rebuilt only when data changes, the app
/// opens, or a notification button is pressed.
class Reminders {
  Reminders(this.service, this.photos);

  final MedService service;
  final PhotoStore photos;
  final plugin = FlutterLocalNotificationsPlugin();
  static const _battery = MethodChannel('med_reminder/battery');

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  Future<void> initialize({void Function(NotificationResponse)? onResponse}) async {
    final l = await _strings();
    await plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          // Asked for during onboarding instead of at first launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(_iosCategory, actions: [
              DarwinNotificationAction.plain(actionTaken, l.markAllTaken),
              DarwinNotificationAction.plain(actionSnooze, l.snooze),
            ]),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );
  }

  Future<NotificationResponse?> launchResponse() async {
    final details = await plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true ? details!.notificationResponse : null;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _android?.requestNotificationsPermission();
      if (await _android?.canScheduleExactNotifications() == false) {
        await _android?.requestExactAlarmsPermission();
      }
    } else {
      await _ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<ReminderHealth> health() async {
    if (Platform.isAndroid) {
      bool? battery;
      try {
        battery = await _battery.invokeMethod<bool>('isUnrestricted');
      } on PlatformException {
        battery = null;
      }
      return ReminderHealth(
        notifications: await _android?.areNotificationsEnabled() ?? false,
        exactAlarms: await _android?.canScheduleExactNotifications() ?? false,
        batteryUnrestricted: battery,
      );
    }
    final perms = await _ios?.checkPermissions();
    return ReminderHealth(notifications: perms?.isEnabled ?? false);
  }

  Future<void> openBatterySettings() => _battery.invokeMethod('openSettings');

  /// Handles a notification button press (app open or closed).
  Future<void> handleResponse(NotificationResponse r) async {
    final slotMs = int.tryParse(r.payload ?? '');
    if (slotMs == null) return;
    final slot = DateTime.fromMillisecondsSinceEpoch(slotMs);
    switch (r.actionId) {
      case actionTaken:
        await service.markSlotTaken(slot);
      case actionSnooze:
        final s = await service.settings();
        await service.snooze(slot, DateTime.now().add(Duration(minutes: s.snoozeMinutes)));
      default:
        return;
    }
    await clearSlot(slot);
    await rescheduleAll();
  }

  /// Removes shown and pending notifications for one dose time.
  Future<void> clearSlot(DateTime slot) async {
    for (var k = 0; k < 8; k++) {
      await plugin.cancel(id: _slotId(slot, k));
    }
  }

  /// Clears a dose time's notifications once nothing at that time is pending.
  Future<void> clearSlotIfDone(DateTime slot) async {
    final doses = await service.dosesBetween(slot, slot.add(const Duration(minutes: 1)));
    if (doses.every((d) => !d.isPending)) await clearSlot(slot);
  }

  Future<void>? _running;
  bool _again = false;

  /// Rebuilds all pending notifications. Calls made while one is running are
  /// merged into a single follow-up run.
  Future<void> rescheduleAll() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = () async {
      try {
        do {
          _again = false;
          await _reschedule();
        } while (_again);
      } finally {
        _running = null;
      }
    }();
  }

  Future<void> _reschedule() async {
    final settings = await service.settings();
    final l = await _strings();
    final fmt = Fmt(l);
    final now = DateTime.now();

    final people = {for (final p in await service.repo.people()) p.id: p};
    final doses = await service.dosesBetween(
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 7)),
    );
    final slots = SplayTreeMap<DateTime, List<Dose>>();
    for (final d in doses.where((d) => d.isPending && settings.remindsFor(d.medicine.personId))) {
      (slots[d.at] ??= []).add(d);
    }
    final snoozes = await service.snoozes();

    // Every notification to send: the reminder itself, then follow-ups until
    // someone marks the doses.
    final entries = <_Entry>[];
    final followUps = settings.followUpMinutes > 0 ? settings.followUpCount : 0;
    for (final MapEntry(key: slot, value: slotDoses) in slots.entries) {
      final snoozed = snoozes[slot.millisecondsSinceEpoch];
      final base = snoozed != null ? DateTime.fromMillisecondsSinceEpoch(snoozed) : slot;
      for (var k = 0; k <= followUps; k++) {
        final when = base.add(Duration(minutes: settings.followUpMinutes * k));
        if (when.isAfter(now)) entries.add(_Entry(when, slot, k, slotDoses));
      }
    }
    entries.sort((a, b) => a.when.compareTo(b.when));

    await plugin.cancelAllPendingNotifications();
    final dirs = await _imageDirs();
    final usedImages = <String>{};
    final mode = await _scheduleMode();

    final fits = entries.length <= _budget;
    final toSend = fits ? entries : entries.sublist(0, _budget - 1);
    for (final e in toSend) {
      final meds = [for (final d in e.doses) d.medicine];
      final image = await _image(meds, dirs.$1, fmt.isArabic);
      if (image != null) usedImages.add(image.path);
      await _schedule(
        id: _slotId(e.slot, e.k),
        when: e.when,
        title: e.k == 0 ? l.notifTitle(fmt.time(e.slot)) : l.notifFollowUpTitle(fmt.time(e.slot)),
        body: _body(e.doses, people, fmt),
        meds: meds,
        image: image,
        iosDir: dirs.$2,
        payload: '${e.slot.millisecondsSinceEpoch}',
        l: l,
        snoozeMinutes: settings.snoozeMinutes,
        mode: mode,
      );
    }
    if (!fits) {
      // Out of room: one last reminder asks the user to open the app, which
      // schedules the next batch.
      await plugin.zonedSchedule(
        id: _openAppId,
        scheduledDate: tz.TZDateTime.from(entries[_budget - 1].when, tz.local),
        title: l.notifOpenAppTitle,
        body: l.notifOpenAppBody,
        notificationDetails: _details(l, actions: false),
        androidScheduleMode: mode,
      );
    }

    // Drop cached images no longer used (Android reads them when shown).
    for (final f in dirs.$1.listSync()) {
      if (!usedImages.contains(f.path)) f.deleteSync();
    }
  }

  /// Shows a sample reminder in 5 seconds, using a real medicine if there is one.
  Future<void> showTest() async {
    final l = await _strings();
    final fmt = Fmt(l);
    final meds = (await service.repo.medicines()).where((m) => m.active).toList()
      ..sort((a, b) => (b.photo != null ? 1 : 0) - (a.photo != null ? 1 : 0));
    final dirs = await _imageDirs();
    final when = DateTime.now().add(const Duration(seconds: 5));
    final sample = meds.take(3).toList();
    await _schedule(
      id: _testId,
      when: when,
      title: l.notifTitle(fmt.time(when)),
      body: sample.isEmpty
          ? l.testMedicine
          : sample.map((m) => '${m.name} — ${fmt.doseLine(m)}').join('\n'),
      meds: sample,
      image: await _image(sample, dirs.$1, fmt.isArabic),
      iosDir: dirs.$2,
      payload: '',
      l: l,
      snoozeMinutes: 0,
      mode: await _scheduleMode(),
      actions: false,
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required List<Medicine> meds,
    required File? image,
    required Directory iosDir,
    required String payload,
    required AppLocalizations l,
    required int snoozeMinutes,
    required AndroidScheduleMode mode,
    bool actions = true,
  }) async {
    final firstPhoto = meds.map((m) => photos.file(m.photo)).whereType<File>().firstOrNull;
    String? iosAttachment;
    if (Platform.isIOS && image != null) {
      // iOS moves attachment files into its own store, so each notification
      // needs its own copy.
      iosAttachment = (await image.copy('${iosDir.path}/$id.png')).path;
    }
    await plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      title: title,
      body: body,
      payload: payload,
      androidScheduleMode: mode,
      notificationDetails: _details(
        l,
        actions: actions,
        body: body,
        title: title,
        single: meds.length == 1,
        image: image?.path,
        largeIcon: firstPhoto?.path,
        iosAttachment: iosAttachment,
      ),
    );
  }

  NotificationDetails _details(
    AppLocalizations l, {
    required bool actions,
    String? title,
    String? body,
    bool single = false,
    String? image,
    String? largeIcon,
    String? iosAttachment,
  }) {
    final StyleInformation? style = image != null
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(image),
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: true,
          )
        : body != null
            ? BigTextStyleInformation(body)
            : null;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l.channelName,
        channelDescription: l.channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        styleInformation: style,
        largeIcon: largeIcon != null ? FilePathAndroidBitmap(largeIcon) : null,
        actions: actions
            ? [
                AndroidNotificationAction(actionTaken, single ? l.taken : l.markAllTaken),
                AndroidNotificationAction(actionSnooze, l.snooze),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: 'doses',
        categoryIdentifier: actions ? _iosCategory : null,
        attachments: iosAttachment != null ? [DarwinNotificationAttachment(iosAttachment)] : null,
      ),
    );
  }

  /// "Lina: Panadol — 1 tablet · After food", one line per medicine.
  String _body(List<Dose> doses, Map<String, Person> people, Fmt fmt) {
    return doses.map((d) {
      final who = people[d.medicine.personId]?.name;
      final line = '${d.medicine.name} — ${fmt.doseLine(d.medicine)}';
      return people.length > 1 && who != null ? '$who: $line' : line;
    }).join('\n');
  }

  Future<File?> _image(List<Medicine> meds, Directory dir, bool rtl) async {
    try {
      return await buildSlotImage(meds, photos, dir, rtl: rtl);
    } catch (e) {
      debugPrint('Could not draw reminder image: $e');
      return null;
    }
  }

  Future<(Directory, Directory)> _imageDirs() async {
    final base = await getApplicationSupportDirectory();
    final images = Directory('${base.path}/notif_images');
    final ios = Directory('${base.path}/notif_ios');
    await images.create(recursive: true);
    if (ios.existsSync()) await ios.delete(recursive: true);
    await ios.create(recursive: true);
    return (images, ios);
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    return exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<AppLocalizations> _strings() async =>
      lookupAppLocalizations(resolveLocale((await service.settings()).language));

  /// Stable notification ids: 8 per dose time (reminder + follow-ups).
  static int _slotId(DateTime slot, int k) =>
      ((slot.millisecondsSinceEpoch ~/ 60000) % 200000000) * 8 + k;
}

/// The app language: the saved choice, or the phone's if it's Arabic or English.
Locale resolveLocale(String setting) {
  if (setting == 'ar' || setting == 'en') return Locale(setting);
  final system = PlatformDispatcher.instance.locale.languageCode;
  return Locale(system == 'ar' ? 'ar' : 'en');
}

class _Entry {
  _Entry(this.when, this.slot, this.k, this.doses);

  final DateTime when;
  final DateTime slot;
  final int k;
  final List<Dose> doses;
}
