enum EventType {
  timeIn,
  timeOut;

  /// Value sent in the submission payload.
  String get value => switch (this) {
    EventType.timeIn  => 'time_in',
    EventType.timeOut => 'time_out',
  };

  /// Display label shown on the home screen buttons.
  String get label => switch (this) {
    EventType.timeIn  => 'Time In',
    EventType.timeOut => 'Time Out',
  };
}