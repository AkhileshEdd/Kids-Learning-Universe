/// App-wide settings controlled from the grown-ups area.
class AppSettings {
  AppSettings({
    this.soundEffects = true,
    this.music = true,
    this.voice = true,
    this.speechRate = 0.42,
    this.readAloudSpanish = false,
    this.dailyLimitMinutes = 0,
    this.voiceLocale = 'en-US',
  });

  bool soundEffects;
  bool music;
  bool voice;

  /// Narration speed passed to the TTS engine (0.5 is normal on Android).
  double speechRate;

  /// Default storybook narration language.
  bool readAloudSpanish;

  /// 0 = no limit.
  int dailyLimitMinutes;

  /// Narrator accent for English speech (en-US, en-GB, en-IN, en-AU).
  String voiceLocale;

  static const voiceLocales = {
    'en-US': 'American',
    'en-GB': 'British',
    'en-IN': 'Indian',
    'en-AU': 'Australian',
  };

  Map<String, dynamic> toJson() => {
        'sfx': soundEffects,
        'music': music,
        'voice': voice,
        'rate': speechRate,
        'es': readAloudSpanish,
        'limit': dailyLimitMinutes,
        'locale': voiceLocale,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        soundEffects: j['sfx'] as bool? ?? true,
        music: j['music'] as bool? ?? true,
        voice: j['voice'] as bool? ?? true,
        speechRate: (j['rate'] as num?)?.toDouble() ?? 0.42,
        readAloudSpanish: j['es'] as bool? ?? false,
        dailyLimitMinutes: j['limit'] as int? ?? 0,
        voiceLocale: j['locale'] as String? ?? 'en-US',
      );
}
