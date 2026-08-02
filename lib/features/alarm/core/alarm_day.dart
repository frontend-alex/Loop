enum AlarmDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday
}

extension AlarmDayLabel on AlarmDay {
  String get shortLabel {
    return switch (this) {
      AlarmDay.monday => 'M',
      AlarmDay.tuesday => 'T',
      AlarmDay.wednesday => 'W',
      AlarmDay.thursday => 'T',
      AlarmDay.friday => 'F',
      AlarmDay.saturday => 'S',
      AlarmDay.sunday => 'S',
    };
  }

  String get fullLabel {
     return switch (this) {
       AlarmDay.monday => 'Monday',
       AlarmDay.tuesday => 'Tuesday',
       AlarmDay.wednesday => 'Wednesday',
       AlarmDay.thursday => 'Thursday',
       AlarmDay.friday => 'Friday',
       AlarmDay.saturday => 'Saturday',
       AlarmDay.sunday => 'Sunday',
    };
  }
}
