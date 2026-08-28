/// Self-reported end-of-day mood. Not a psychological or medical
/// measurement — just how the user says they felt about the day (see
/// docs/PRODUCT.md).
enum Mood {
  excellent,
  good,
  okay,
  difficult,
  unproductive;

  static Mood fromDb(String value) => Mood.values.firstWhere(
        (m) => m.name == value,
        orElse: () => Mood.okay,
      );

  String toDb() => name;

  String get label => switch (this) {
        Mood.excellent => 'Excellent',
        Mood.good => 'Good',
        Mood.okay => 'Okay',
        Mood.difficult => 'Difficult',
        Mood.unproductive => 'Unproductive',
      };
}
