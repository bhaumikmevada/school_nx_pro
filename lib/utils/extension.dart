extension DateTimeHelper on DateTime {
  String toDDMMYYYY() {
    return '$day/${month < 10 ? '0$month' : month}/$year';
  }

  String toStandard({bool time = true}) {
    int hour0 = hour > 12 ? hour - 12 : hour;
    return '${time ? '${hour0 < 10 ? '0$hour0' : hour0}:${minute < 10 ? '0$minute' : minute} ${hour < 12 ? 'AM' : 'PM'} ' : ''}$day ${month.intToMonth()} $year';
  }

  String toDate() {
    return '$day ${month.intToMonth()}';
  }

  String toTime() {
    int hour0 = hour > 12 ? hour - 12 : hour;
    return '${hour0 < 10 ? '0$hour0' : hour0}:${minute < 10 ? '0$minute' : minute} ${hour < 12 ? 'AM' : 'PM'}';
  }

  String toMMDDYYYY() {
    return '$month/$day/$year';
  }

  bool gotPast() {
    DateTime now = DateTime.now();
    return now.isAfter(this);
  }
}

extension IntHelper on int {
  String intToMonth() {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[this - 1];
  }
}
