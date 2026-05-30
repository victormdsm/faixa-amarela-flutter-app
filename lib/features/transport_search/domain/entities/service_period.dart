enum ServicePeriod { morning, afternoon, night, fullTime }

extension ServicePeriodX on ServicePeriod {
  String get label => switch (this) {
    ServicePeriod.morning => 'Manha',
    ServicePeriod.afternoon => 'Tarde',
    ServicePeriod.night => 'Noite',
    ServicePeriod.fullTime => 'Integral',
  };

  String get shortLabel => label;

  String get apiValue => switch (this) {
    ServicePeriod.morning => 'morning',
    ServicePeriod.afternoon => 'afternoon',
    ServicePeriod.night => 'night',
    ServicePeriod.fullTime => 'full_time',
  };
}
