import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoTimePicker extends StatelessWidget {
  const CupertinoTimePicker({
    required this.time,
    required this.onChanged,
    super.key,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  DateTime _initialDateTime() {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
  }

  void _onDateTimeChanged(DateTime dateTime) {
    onChanged(TimeOfDay.fromDateTime(dateTime));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 216,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: _initialDateTime(),
        use24hFormat: false,
        minuteInterval: 1,
        onDateTimeChanged: _onDateTimeChanged,
      ),
    );
  }
}