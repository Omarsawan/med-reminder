import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Med Reminder'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get navMedicines;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Who takes medicines?'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Add everyone you manage medicines for. You can change this later.'**
  String get welcomeBody;

  /// No description provided for @personNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. Mom'**
  String get personNameHint;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @todayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No medicines yet'**
  String get todayEmptyTitle;

  /// No description provided for @todayEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a medicine and its reminders will show up here.'**
  String get todayEmptyBody;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get addMedicine;

  /// No description provided for @noDosesToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled for today.'**
  String get noDosesToday;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @markAllTaken.
  ///
  /// In en, this message translates to:
  /// **'All taken'**
  String get markAllTaken;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @takenAt.
  ///
  /// In en, this message translates to:
  /// **'Taken {time}'**
  String takenAt(String time);

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @stateDue.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get stateDue;

  /// No description provided for @stateMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get stateMissed;

  /// No description provided for @stateUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get stateUpcoming;

  /// No description provided for @stateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stateDone;

  /// No description provided for @asNeededSection.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get asNeededSection;

  /// No description provided for @takeNow.
  ///
  /// In en, this message translates to:
  /// **'Take now'**
  String get takeNow;

  /// No description provided for @lastTaken.
  ///
  /// In en, this message translates to:
  /// **'Last taken {time}'**
  String lastTaken(String time);

  /// No description provided for @nextAllowedAt.
  ///
  /// In en, this message translates to:
  /// **'Next dose from {time}'**
  String nextAllowedAt(String time);

  /// No description provided for @tooSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Too soon?'**
  String get tooSoonTitle;

  /// No description provided for @tooSoonBody.
  ///
  /// In en, this message translates to:
  /// **'The last dose was at {time}. Keep at least {hours} hours between doses. Take it anyway?'**
  String tooSoonBody(String time, String hours);

  /// No description provided for @maxPerDayBody.
  ///
  /// In en, this message translates to:
  /// **'Already taken {count} times today (limit {max}). Take it anyway?'**
  String maxPerDayBody(int count, int max);

  /// No description provided for @takeAnyway.
  ///
  /// In en, this message translates to:
  /// **'Take anyway'**
  String get takeAnyway;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'{name}: only {amount} left. Time to refill.'**
  String lowStock(String name, String amount);

  /// No description provided for @dosesTakenOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} taken'**
  String dosesTakenOf(int done, int total);

  /// No description provided for @editMedicine.
  ///
  /// In en, this message translates to:
  /// **'Edit medicine'**
  String get editMedicine;

  /// No description provided for @newMedicine.
  ///
  /// In en, this message translates to:
  /// **'New medicine'**
  String get newMedicine;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @photoHelp.
  ///
  /// In en, this message translates to:
  /// **'A photo of the pill or box shows on every reminder.'**
  String get photoHelp;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine name'**
  String get medicineName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameRequired;

  /// No description provided for @whoTakesIt.
  ///
  /// In en, this message translates to:
  /// **'Who takes it?'**
  String get whoTakesIt;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get addPerson;

  /// No description provided for @colorTag.
  ///
  /// In en, this message translates to:
  /// **'Colour tag'**
  String get colorTag;

  /// No description provided for @typeAndDose.
  ///
  /// In en, this message translates to:
  /// **'Type and dose'**
  String get typeAndDose;

  /// No description provided for @whenToTake.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get whenToTake;

  /// No description provided for @scheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get scheduleDaily;

  /// No description provided for @scheduleInterval.
  ///
  /// In en, this message translates to:
  /// **'Every few hours'**
  String get scheduleInterval;

  /// No description provided for @scheduleWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Some days'**
  String get scheduleWeekdays;

  /// No description provided for @scheduleAsNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get scheduleAsNeeded;

  /// No description provided for @presetTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Once} =2{Twice} other{{count} times}}'**
  String presetTimes(int count);

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTime;

  /// No description provided for @everyHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every hour} other{Every {count} hours}}'**
  String everyHours(int count);

  /// No description provided for @firstDoseAt.
  ///
  /// In en, this message translates to:
  /// **'First dose at'**
  String get firstDoseAt;

  /// No description provided for @minGapLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours between doses (at least)'**
  String get minGapLabel;

  /// No description provided for @maxPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Max per day'**
  String get maxPerDayLabel;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @pickDays.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day'**
  String get pickDays;

  /// No description provided for @pickTimes.
  ///
  /// In en, this message translates to:
  /// **'Add at least one time'**
  String get pickTimes;

  /// No description provided for @pickPerson.
  ///
  /// In en, this message translates to:
  /// **'Choose who takes it'**
  String get pickPerson;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get durationLabel;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @forSetDays.
  ///
  /// In en, this message translates to:
  /// **'Set number of days'**
  String get forSetDays;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @startsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String startsOn(String date);

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @instrNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get instrNone;

  /// No description provided for @instrBeforeFood.
  ///
  /// In en, this message translates to:
  /// **'Before food'**
  String get instrBeforeFood;

  /// No description provided for @instrWithFood.
  ///
  /// In en, this message translates to:
  /// **'With food'**
  String get instrWithFood;

  /// No description provided for @instrAfterFood.
  ///
  /// In en, this message translates to:
  /// **'After food'**
  String get instrAfterFood;

  /// No description provided for @instrEmptyStomach.
  ///
  /// In en, this message translates to:
  /// **'Empty stomach'**
  String get instrEmptyStomach;

  /// No description provided for @instrBedtime.
  ///
  /// In en, this message translates to:
  /// **'At bedtime'**
  String get instrBedtime;

  /// No description provided for @trackStock.
  ///
  /// In en, this message translates to:
  /// **'Track how many are left'**
  String get trackStock;

  /// No description provided for @stockLeft.
  ///
  /// In en, this message translates to:
  /// **'Left now'**
  String get stockLeft;

  /// No description provided for @warnAt.
  ///
  /// In en, this message translates to:
  /// **'Warn at'**
  String get warnAt;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notes;

  /// No description provided for @pauseReminders.
  ///
  /// In en, this message translates to:
  /// **'Pause reminders'**
  String get pauseReminders;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteTitle(String name);

  /// No description provided for @deleteMedicineBody.
  ///
  /// In en, this message translates to:
  /// **'Its reminders and history will be removed.'**
  String get deleteMedicineBody;

  /// No description provided for @noColor.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noColor;

  /// No description provided for @medicinesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No medicines yet. Tap + to add one.'**
  String get medicinesEmpty;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Course finished'**
  String get finished;

  /// No description provided for @leftCount.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String leftCount(String amount);

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last day} other{{count} days left}}'**
  String daysLeft(int count);

  /// No description provided for @everyHoursFrom.
  ///
  /// In en, this message translates to:
  /// **'{every} from {time}'**
  String everyHoursFrom(String every, String time);

  /// No description provided for @asNeededSummary.
  ///
  /// In en, this message translates to:
  /// **'As needed · {hours}h apart'**
  String asNeededSummary(String hours);

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet.'**
  String get historyEmpty;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get systemLanguage;

  /// No description provided for @remindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersSection;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'Repeat if not marked'**
  String get followUp;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @followUpCount.
  ///
  /// In en, this message translates to:
  /// **'Repeat up to'**
  String get followUpCount;

  /// No description provided for @timesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{once} =2{twice} other{{count} times}}'**
  String timesCount(int count);

  /// No description provided for @snoozeFor.
  ///
  /// In en, this message translates to:
  /// **'Snooze for'**
  String get snoozeFor;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @reminderCheck.
  ///
  /// In en, this message translates to:
  /// **'Reminder check'**
  String get reminderCheck;

  /// No description provided for @notificationsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get notificationsAllowed;

  /// No description provided for @exactAlarms.
  ///
  /// In en, this message translates to:
  /// **'On-time alarms'**
  String get exactAlarms;

  /// No description provided for @batteryUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'Not cancelled by battery saver'**
  String get batteryUnrestricted;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @batteryHelp.
  ///
  /// In en, this message translates to:
  /// **'Reminders are handed to the phone\'s alarm system, so this app never runs in the background and uses almost no battery. Some phones (Samsung, Xiaomi, Huawei) still cancel alarms of \"optimised\" apps. If reminders go missing, set this app to Unrestricted.'**
  String get batteryHelp;

  /// No description provided for @sendTestReminder.
  ///
  /// In en, this message translates to:
  /// **'Send a test reminder'**
  String get sendTestReminder;

  /// No description provided for @testReminderSent.
  ///
  /// In en, this message translates to:
  /// **'A test reminder will appear in 5 seconds.'**
  String get testReminderSent;

  /// No description provided for @personName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personName;

  /// No description provided for @deletePersonBlocked.
  ///
  /// In en, this message translates to:
  /// **'Delete or move {name}\'s medicines first.'**
  String deletePersonBlocked(String name);

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'{time} · Time for medicine'**
  String notifTitle(String time);

  /// No description provided for @notifFollowUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {time} doses not marked yet'**
  String notifFollowUpTitle(String time);

  /// No description provided for @notifOpenAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Med Reminder'**
  String get notifOpenAppTitle;

  /// No description provided for @notifOpenAppBody.
  ///
  /// In en, this message translates to:
  /// **'Open the app so your next reminders keep coming.'**
  String get notifOpenAppBody;

  /// No description provided for @channelName.
  ///
  /// In en, this message translates to:
  /// **'Medicine reminders'**
  String get channelName;

  /// No description provided for @channelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders to take medicines on time'**
  String get channelDescription;

  /// No description provided for @testMedicine.
  ///
  /// In en, this message translates to:
  /// **'Test medicine'**
  String get testMedicine;

  /// No description provided for @allDone.
  ///
  /// In en, this message translates to:
  /// **'All done for this time'**
  String get allDone;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @unitTablet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} tablet} other{{amount} tablets}}'**
  String unitTablet(int count, String amount);

  /// No description provided for @unitCapsule.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} capsule} other{{amount} capsules}}'**
  String unitCapsule(int count, String amount);

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{amount} ml}}'**
  String unitMl(int count, String amount);

  /// No description provided for @unitDrop.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} drop} other{{amount} drops}}'**
  String unitDrop(int count, String amount);

  /// No description provided for @unitPuff.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} puff} other{{amount} puffs}}'**
  String unitPuff(int count, String amount);

  /// No description provided for @unitUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} unit} other{{amount} units}}'**
  String unitUnit(int count, String amount);

  /// No description provided for @unitSachet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{amount} sachet} other{{amount} sachets}}'**
  String unitSachet(int count, String amount);

  /// No description provided for @unitApplication.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Apply once} other{Apply {amount} times}}'**
  String unitApplication(int count, String amount);

  /// No description provided for @nameTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get nameTablet;

  /// No description provided for @nameCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get nameCapsule;

  /// No description provided for @nameMl.
  ///
  /// In en, this message translates to:
  /// **'Liquid (ml)'**
  String get nameMl;

  /// No description provided for @nameDrop.
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get nameDrop;

  /// No description provided for @namePuff.
  ///
  /// In en, this message translates to:
  /// **'Inhaler'**
  String get namePuff;

  /// No description provided for @nameUnit.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get nameUnit;

  /// No description provided for @nameSachet.
  ///
  /// In en, this message translates to:
  /// **'Sachet'**
  String get nameSachet;

  /// No description provided for @nameApplication.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get nameApplication;

  /// No description provided for @scheduleEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'Every few days'**
  String get scheduleEveryNDays;

  /// No description provided for @everyDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} =2{Every other day} other{Every {count} days}}'**
  String everyDays(int count);

  /// No description provided for @firstDoseOn.
  ///
  /// In en, this message translates to:
  /// **'First dose on {date}'**
  String firstDoseOn(String date);

  /// No description provided for @nextDoseOn.
  ///
  /// In en, this message translates to:
  /// **'next {date}'**
  String nextDoseOn(String date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
