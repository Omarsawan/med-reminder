// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تذكير الدواء';

  @override
  String get navToday => 'اليوم';

  @override
  String get navMedicines => 'الأدوية';

  @override
  String get navHistory => 'السجل';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get welcomeTitle => 'من يتناول الأدوية؟';

  @override
  String get welcomeBody => 'أضف كل من تتابع أدويته. يمكنك التعديل لاحقًا.';

  @override
  String get personNameHint => 'الاسم، مثلًا: ماما';

  @override
  String get add => 'إضافة';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get undo => 'تراجع';

  @override
  String get todayEmptyTitle => 'لا توجد أدوية بعد';

  @override
  String get todayEmptyBody => 'أضف دواءً وستظهر تذكيراته هنا.';

  @override
  String get addMedicine => 'إضافة دواء';

  @override
  String get noDosesToday => 'لا شيء مجدول اليوم.';

  @override
  String get everyone => 'الجميع';

  @override
  String get markAllTaken => 'تم أخذ الكل';

  @override
  String get taken => 'تم الأخذ';

  @override
  String get skip => 'تخطي';

  @override
  String get snooze => 'تأجيل';

  @override
  String takenAt(String time) {
    return 'أُخذ $time';
  }

  @override
  String get skipped => 'تم التخطي';

  @override
  String get stateDue => 'حان الوقت';

  @override
  String get stateMissed => 'فائت';

  @override
  String get stateUpcoming => 'قادم';

  @override
  String get stateDone => 'تم';

  @override
  String get asNeededSection => 'عند الحاجة';

  @override
  String get takeNow => 'أخذ الآن';

  @override
  String lastTaken(String time) {
    return 'آخر جرعة $time';
  }

  @override
  String nextAllowedAt(String time) {
    return 'الجرعة التالية بعد $time';
  }

  @override
  String get tooSoonTitle => 'مبكر جدًا؟';

  @override
  String tooSoonBody(String time, String hours) {
    return 'آخر جرعة كانت $time. يجب ترك $hours ساعات على الأقل بين الجرعات. هل تريد الأخذ على أي حال؟';
  }

  @override
  String maxPerDayBody(int count, int max) {
    return 'أُخذ $count مرات اليوم (الحد $max). هل تريد الأخذ على أي حال؟';
  }

  @override
  String get takeAnyway => 'أخذ على أي حال';

  @override
  String lowStock(String name, String amount) {
    return '$name: تبقى $amount فقط. حان وقت إعادة الشراء.';
  }

  @override
  String dosesTakenOf(int done, int total) {
    return 'تم أخذ $done من $total';
  }

  @override
  String get editMedicine => 'تعديل الدواء';

  @override
  String get newMedicine => 'دواء جديد';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get photoHelp => 'صورة الحبة أو العلبة تظهر في كل تذكير.';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get medicineName => 'اسم الدواء';

  @override
  String get nameRequired => 'أدخل الاسم';

  @override
  String get whoTakesIt => 'لمن هذا الدواء؟';

  @override
  String get addPerson => 'إضافة شخص';

  @override
  String get colorTag => 'لون مميز';

  @override
  String get typeAndDose => 'النوع والجرعة';

  @override
  String get whenToTake => 'متى';

  @override
  String get scheduleDaily => 'كل يوم';

  @override
  String get scheduleInterval => 'كل عدة ساعات';

  @override
  String get scheduleWeekdays => 'أيام محددة';

  @override
  String get scheduleAsNeeded => 'عند الحاجة';

  @override
  String presetTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرات',
      two: 'مرتين',
      one: 'مرة',
    );
    return '$_temp0';
  }

  @override
  String get addTime => 'إضافة وقت';

  @override
  String everyHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'كل $count ساعة',
      few: 'كل $count ساعات',
      two: 'كل ساعتين',
      one: 'كل ساعة',
    );
    return '$_temp0';
  }

  @override
  String get firstDoseAt => 'أول جرعة الساعة';

  @override
  String get minGapLabel => 'أقل عدد ساعات بين الجرعات';

  @override
  String get maxPerDayLabel => 'الحد الأقصى يوميًا';

  @override
  String get noLimit => 'بلا حد';

  @override
  String get pickDays => 'اختر يومًا واحدًا على الأقل';

  @override
  String get pickTimes => 'أضف وقتًا واحدًا على الأقل';

  @override
  String get pickPerson => 'اختر لمن هذا الدواء';

  @override
  String get durationLabel => 'المدة';

  @override
  String get ongoing => 'مستمر';

  @override
  String get forSetDays => 'عدد أيام محدد';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String startsOn(String date) {
    return 'يبدأ $date';
  }

  @override
  String get instructions => 'التعليمات';

  @override
  String get instrNone => 'بدون';

  @override
  String get instrBeforeFood => 'قبل الأكل';

  @override
  String get instrWithFood => 'مع الأكل';

  @override
  String get instrAfterFood => 'بعد الأكل';

  @override
  String get instrEmptyStomach => 'على معدة فارغة';

  @override
  String get instrBedtime => 'قبل النوم';

  @override
  String get trackStock => 'تتبع الكمية المتبقية';

  @override
  String get stockLeft => 'المتبقي الآن';

  @override
  String get warnAt => 'التنبيه عند';

  @override
  String get notes => 'ملاحظات (اختياري)';

  @override
  String get pauseReminders => 'إيقاف التذكيرات مؤقتًا';

  @override
  String deleteTitle(String name) {
    return 'حذف $name؟';
  }

  @override
  String get deleteMedicineBody => 'ستُحذف تذكيراته وسجله.';

  @override
  String get noColor => 'بدون';

  @override
  String get medicinesEmpty => 'لا توجد أدوية بعد. اضغط + للإضافة.';

  @override
  String get paused => 'متوقف مؤقتًا';

  @override
  String get finished => 'انتهى العلاج';

  @override
  String leftCount(String amount) {
    return 'متبقي $amount';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'باقي $count يومًا',
      few: 'باقي $count أيام',
      two: 'باقي يومان',
      one: 'آخر يوم',
    );
    return '$_temp0';
  }

  @override
  String everyHoursFrom(String every, String time) {
    return '$every بدءًا من $time';
  }

  @override
  String asNeededSummary(String hours) {
    return 'عند الحاجة · بفارق $hours ساعات';
  }

  @override
  String get historyEmpty => 'لا يوجد سجل بعد.';

  @override
  String get language => 'اللغة';

  @override
  String get systemLanguage => 'لغة الهاتف';

  @override
  String get remindersSection => 'التذكيرات';

  @override
  String get followUp => 'التكرار إذا لم يُسجَّل';

  @override
  String get off => 'إيقاف';

  @override
  String minutesShort(int count) {
    return '$count د';
  }

  @override
  String get followUpCount => 'عدد مرات التكرار';

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرات',
      two: 'مرتين',
      one: 'مرة',
    );
    return '$_temp0';
  }

  @override
  String get snoozeFor => 'مدة التأجيل';

  @override
  String get people => 'الأشخاص';

  @override
  String get reminderCheck => 'فحص التذكيرات';

  @override
  String get notificationsAllowed => 'السماح بالإشعارات';

  @override
  String get exactAlarms => 'التنبيه في الوقت المحدد';

  @override
  String get batteryUnrestricted => 'غير مقيَّد بموفر البطارية';

  @override
  String get fix => 'إصلاح';

  @override
  String get batteryHelp =>
      'تُسلَّم التذكيرات لنظام المنبه في الهاتف، فلا يعمل التطبيق في الخلفية ولا يستهلك البطارية تقريبًا. بعض الهواتف (سامسونج، شاومي، هواوي) تلغي منبهات التطبيقات \"المحسّنة\". إذا لم تصل التذكيرات، اجعل هذا التطبيق \"غير مقيَّد\".';

  @override
  String get sendTestReminder => 'إرسال تذكير تجريبي';

  @override
  String get testReminderSent => 'سيظهر تذكير تجريبي خلال 5 ثوانٍ.';

  @override
  String get personName => 'الاسم';

  @override
  String deletePersonBlocked(String name) {
    return 'احذف أدوية $name أو انقلها أولًا.';
  }

  @override
  String notifTitle(String time) {
    return '$time · حان وقت الدواء';
  }

  @override
  String notifFollowUpTitle(String time) {
    return 'تذكير: لم تُسجَّل جرعات $time بعد';
  }

  @override
  String get notifOpenAppTitle => 'افتح تذكير الدواء';

  @override
  String get notifOpenAppBody => 'افتح التطبيق لتستمر التذكيرات القادمة.';

  @override
  String get channelName => 'تذكيرات الأدوية';

  @override
  String get channelDescription => 'تذكيرات لأخذ الأدوية في وقتها';

  @override
  String get testMedicine => 'دواء تجريبي';

  @override
  String get allDone => 'تم أخذ كل جرعات هذا الوقت';

  @override
  String get requiredField => 'مطلوب';

  @override
  String unitTablet(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount قرص',
      many: '$amount قرصًا',
      few: '$amount أقراص',
      two: 'قرصان',
      one: 'قرص واحد',
    );
    return '$_temp0';
  }

  @override
  String unitCapsule(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount كبسولة',
      many: '$amount كبسولة',
      few: '$amount كبسولات',
      two: 'كبسولتان',
      one: 'كبسولة واحدة',
    );
    return '$_temp0';
  }

  @override
  String unitMl(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount مل',
    );
    return '$_temp0';
  }

  @override
  String unitDrop(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount نقطة',
      many: '$amount نقطة',
      few: '$amount نقاط',
      two: 'نقطتان',
      one: 'نقطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String unitPuff(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount بخة',
      many: '$amount بخة',
      few: '$amount بخات',
      two: 'بختان',
      one: 'بخة واحدة',
    );
    return '$_temp0';
  }

  @override
  String unitUnit(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount وحدة',
      many: '$amount وحدة',
      few: '$amount وحدات',
      two: 'وحدتان',
      one: 'وحدة واحدة',
    );
    return '$_temp0';
  }

  @override
  String unitSachet(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount كيس',
      many: '$amount كيسًا',
      few: '$amount أكياس',
      two: 'كيسان',
      one: 'كيس واحد',
    );
    return '$_temp0';
  }

  @override
  String unitApplication(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دهان $amount مرات',
      two: 'دهان مرتين',
      one: 'دهان مرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get nameTablet => 'قرص';

  @override
  String get nameCapsule => 'كبسولة';

  @override
  String get nameMl => 'شراب (مل)';

  @override
  String get nameDrop => 'نقط';

  @override
  String get namePuff => 'بخاخ';

  @override
  String get nameUnit => 'حقنة';

  @override
  String get nameSachet => 'كيس';

  @override
  String get nameApplication => 'كريم';

  @override
  String get scheduleEveryNDays => 'كل عدة أيام';

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'كل $count يومًا',
      few: 'كل $count أيام',
      two: 'كل يومين',
      one: 'كل يوم',
    );
    return '$_temp0';
  }

  @override
  String firstDoseOn(String date) {
    return 'أول جرعة يوم $date';
  }

  @override
  String nextDoseOn(String date) {
    return 'التالية $date';
  }
}
