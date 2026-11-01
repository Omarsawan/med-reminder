class AppSettings {
  const AppSettings({
    this.language = 'system',
    this.followUpMinutes = 10,
    this.followUpCount = 3,
    this.snoozeMinutes = 10,
    this.onboarded = false,
  });

  /// 'system', 'en' or 'ar'.
  final String language;

  /// Repeat an unanswered reminder every this many minutes; 0 turns it off.
  final int followUpMinutes;

  /// How many times to repeat an unanswered reminder.
  final int followUpCount;
  final int snoozeMinutes;
  final bool onboarded;

  AppSettings copyWith({
    String? language,
    int? followUpMinutes,
    int? followUpCount,
    int? snoozeMinutes,
    bool? onboarded,
  }) =>
      AppSettings(
        language: language ?? this.language,
        followUpMinutes: followUpMinutes ?? this.followUpMinutes,
        followUpCount: followUpCount ?? this.followUpCount,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
        onboarded: onboarded ?? this.onboarded,
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'followUpMinutes': followUpMinutes,
        'followUpCount': followUpCount,
        'snoozeMinutes': snoozeMinutes,
        'onboarded': onboarded,
      };

  factory AppSettings.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const AppSettings();
    return AppSettings(
      language: j['language'] as String? ?? 'system',
      followUpMinutes: j['followUpMinutes'] as int? ?? 10,
      followUpCount: j['followUpCount'] as int? ?? 3,
      snoozeMinutes: j['snoozeMinutes'] as int? ?? 10,
      onboarded: j['onboarded'] as bool? ?? false,
    );
  }
}
