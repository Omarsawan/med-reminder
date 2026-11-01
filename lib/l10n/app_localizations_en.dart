// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Med Reminder';

  @override
  String get navToday => 'Today';

  @override
  String get navMedicines => 'Medicines';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get welcomeTitle => 'Who takes medicines?';

  @override
  String get welcomeBody =>
      'Add everyone you manage medicines for. You can change this later.';

  @override
  String get personNameHint => 'Name, e.g. Mom';

  @override
  String get add => 'Add';

  @override
  String get continueLabel => 'Continue';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get undo => 'Undo';

  @override
  String get todayEmptyTitle => 'No medicines yet';

  @override
  String get todayEmptyBody =>
      'Add a medicine and its reminders will show up here.';

  @override
  String get addMedicine => 'Add medicine';

  @override
  String get noDosesToday => 'Nothing scheduled for today.';

  @override
  String get everyone => 'Everyone';

  @override
  String get markAllTaken => 'All taken';

  @override
  String get taken => 'Taken';

  @override
  String get skip => 'Skip';

  @override
  String get snooze => 'Snooze';

  @override
  String takenAt(String time) {
    return 'Taken $time';
  }

  @override
  String get skipped => 'Skipped';

  @override
  String get stateDue => 'Due now';

  @override
  String get stateMissed => 'Missed';

  @override
  String get stateUpcoming => 'Upcoming';

  @override
  String get stateDone => 'Done';

  @override
  String get asNeededSection => 'As needed';

  @override
  String get takeNow => 'Take now';

  @override
  String lastTaken(String time) {
    return 'Last taken $time';
  }

  @override
  String nextAllowedAt(String time) {
    return 'Next dose from $time';
  }

  @override
  String get tooSoonTitle => 'Too soon?';

  @override
  String tooSoonBody(String time, String hours) {
    return 'The last dose was at $time. Keep at least $hours hours between doses. Take it anyway?';
  }

  @override
  String maxPerDayBody(int count, int max) {
    return 'Already taken $count times today (limit $max). Take it anyway?';
  }

  @override
  String get takeAnyway => 'Take anyway';

  @override
  String lowStock(String name, String amount) {
    return '$name: only $amount left. Time to refill.';
  }

  @override
  String dosesTakenOf(int done, int total) {
    return '$done of $total taken';
  }

  @override
  String get editMedicine => 'Edit medicine';

  @override
  String get newMedicine => 'New medicine';

  @override
  String get addPhoto => 'Add a photo';

  @override
  String get photoHelp => 'A photo of the pill or box shows on every reminder.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get medicineName => 'Medicine name';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String get whoTakesIt => 'Who takes it?';

  @override
  String get addPerson => 'Add person';

  @override
  String get colorTag => 'Colour tag';

  @override
  String get typeAndDose => 'Type and dose';

  @override
  String get whenToTake => 'When';

  @override
  String get scheduleDaily => 'Every day';

  @override
  String get scheduleInterval => 'Every few hours';

  @override
  String get scheduleWeekdays => 'Some days';

  @override
  String get scheduleAsNeeded => 'As needed';

  @override
  String presetTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      two: 'Twice',
      one: 'Once',
    );
    return '$_temp0';
  }

  @override
  String get addTime => 'Add time';

  @override
  String everyHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count hours',
      one: 'Every hour',
    );
    return '$_temp0';
  }

  @override
  String get firstDoseAt => 'First dose at';

  @override
  String get minGapLabel => 'Hours between doses (at least)';

  @override
  String get maxPerDayLabel => 'Max per day';

  @override
  String get noLimit => 'No limit';

  @override
  String get pickDays => 'Pick at least one day';

  @override
  String get pickTimes => 'Add at least one time';

  @override
  String get pickPerson => 'Choose who takes it';

  @override
  String get durationLabel => 'How long';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get forSetDays => 'Set number of days';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String startsOn(String date) {
    return 'Starts $date';
  }

  @override
  String get instructions => 'Instructions';

  @override
  String get instrNone => 'None';

  @override
  String get instrBeforeFood => 'Before food';

  @override
  String get instrWithFood => 'With food';

  @override
  String get instrAfterFood => 'After food';

  @override
  String get instrEmptyStomach => 'Empty stomach';

  @override
  String get instrBedtime => 'At bedtime';

  @override
  String get trackStock => 'Track how many are left';

  @override
  String get stockLeft => 'Left now';

  @override
  String get warnAt => 'Warn at';

  @override
  String get notes => 'Notes (optional)';

  @override
  String get pauseReminders => 'Pause reminders';

  @override
  String deleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteMedicineBody => 'Its reminders and history will be removed.';

  @override
  String get noColor => 'None';

  @override
  String get medicinesEmpty => 'No medicines yet. Tap + to add one.';

  @override
  String get paused => 'Paused';

  @override
  String get finished => 'Course finished';

  @override
  String leftCount(String amount) {
    return '$amount left';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String everyHoursFrom(String every, String time) {
    return '$every from $time';
  }

  @override
  String asNeededSummary(String hours) {
    return 'As needed · ${hours}h apart';
  }

  @override
  String get historyEmpty => 'Nothing recorded yet.';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Phone language';

  @override
  String get remindersSection => 'Reminders';

  @override
  String get followUp => 'Repeat if not marked';

  @override
  String get off => 'Off';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get followUpCount => 'Repeat up to';

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      two: 'twice',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String get snoozeFor => 'Snooze for';

  @override
  String get people => 'People';

  @override
  String get reminderCheck => 'Reminder check';

  @override
  String get notificationsAllowed => 'Notifications allowed';

  @override
  String get exactAlarms => 'On-time alarms';

  @override
  String get batteryUnrestricted => 'Not cancelled by battery saver';

  @override
  String get fix => 'Fix';

  @override
  String get batteryHelp =>
      'Reminders are handed to the phone\'s alarm system, so this app never runs in the background and uses almost no battery. Some phones (Samsung, Xiaomi, Huawei) still cancel alarms of \"optimised\" apps. If reminders go missing, set this app to Unrestricted.';

  @override
  String get sendTestReminder => 'Send a test reminder';

  @override
  String get testReminderSent => 'A test reminder will appear in 5 seconds.';

  @override
  String get personName => 'Name';

  @override
  String deletePersonBlocked(String name) {
    return 'Delete or move $name\'s medicines first.';
  }

  @override
  String notifTitle(String time) {
    return '$time · Time for medicine';
  }

  @override
  String notifFollowUpTitle(String time) {
    return 'Reminder: $time doses not marked yet';
  }

  @override
  String get notifOpenAppTitle => 'Open Med Reminder';

  @override
  String get notifOpenAppBody =>
      'Open the app so your next reminders keep coming.';

  @override
  String get channelName => 'Medicine reminders';

  @override
  String get channelDescription => 'Reminders to take medicines on time';

  @override
  String get testMedicine => 'Test medicine';

  @override
  String get allDone => 'All done for this time';

  @override
  String get requiredField => 'Required';

  @override
  String unitTablet(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount tablets',
      one: '$amount tablet',
    );
    return '$_temp0';
  }

  @override
  String unitCapsule(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount capsules',
      one: '$amount capsule',
    );
    return '$_temp0';
  }

  @override
  String unitMl(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount ml',
    );
    return '$_temp0';
  }

  @override
  String unitDrop(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount drops',
      one: '$amount drop',
    );
    return '$_temp0';
  }

  @override
  String unitPuff(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount puffs',
      one: '$amount puff',
    );
    return '$_temp0';
  }

  @override
  String unitUnit(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount units',
      one: '$amount unit',
    );
    return '$_temp0';
  }

  @override
  String unitSachet(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount sachets',
      one: '$amount sachet',
    );
    return '$_temp0';
  }

  @override
  String unitApplication(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Apply $amount times',
      one: 'Apply once',
    );
    return '$_temp0';
  }

  @override
  String get nameTablet => 'Tablet';

  @override
  String get nameCapsule => 'Capsule';

  @override
  String get nameMl => 'Liquid (ml)';

  @override
  String get nameDrop => 'Drops';

  @override
  String get namePuff => 'Inhaler';

  @override
  String get nameUnit => 'Injection';

  @override
  String get nameSachet => 'Sachet';

  @override
  String get nameApplication => 'Cream';

  @override
  String get scheduleEveryNDays => 'Every few days';

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      two: 'Every other day',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String firstDoseOn(String date) {
    return 'First dose on $date';
  }

  @override
  String get familySharing => 'Family sharing';

  @override
  String get familyIntro =>
      'Share medicines, photos and doses with another phone, so you both see what was taken.';

  @override
  String get createFamily => 'Create a family code';

  @override
  String get joinFamily => 'Join with a code';

  @override
  String get familyCode => 'Family code';

  @override
  String get familyCodeHelp =>
      'On the other phone, open Settings → Family sharing → Join with a code, and type this code.';

  @override
  String get enterCode => 'Family code from the other phone';

  @override
  String get join => 'Join';

  @override
  String get joinMergeNote =>
      'Anything already on this phone is added to the family\'s list.';

  @override
  String get leaveFamily => 'Stop sharing on this phone';

  @override
  String get leaveFamilyBody =>
      'This phone keeps its data but stops sending and receiving changes.';

  @override
  String get syncSynced => 'Up to date';

  @override
  String get syncOffline =>
      'Offline. Changes will be sent when you\'re back online.';

  @override
  String get syncConnecting => 'Connecting…';

  @override
  String get syncError =>
      'Sync problem. It will retry next time the app opens.';

  @override
  String get syncUnavailable =>
      'Sharing isn\'t set up in this version of the app.';

  @override
  String get syncOff => 'Not shared';

  @override
  String get badCode => 'That code wasn\'t found. Check it and try again.';

  @override
  String get networkError =>
      'Couldn\'t connect. Check the internet and try again.';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get copy => 'Copy';

  @override
  String get remindFor => 'Remind on this phone for';

  @override
  String get remindForHelp =>
      'Each phone chooses for itself. Doses marked on one phone show on the other when its app is opened.';

  @override
  String get joinFromWelcome =>
      'Already using the app on another phone? Join with a family code';

  @override
  String get dueToday => 'Due today';

  @override
  String get notDueToday => 'Not due today';

  @override
  String get pausedOrFinished => 'Paused or finished';

  @override
  String nextDue(String when) {
    return 'Next: $when';
  }
}
