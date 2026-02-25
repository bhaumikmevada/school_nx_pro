class HolidayModel {
  final int holidayID;
  final String eventName;
  final String holidayForMonthDate;
  final String holidayOn;

  HolidayModel({
    required this.holidayID,
    required this.eventName,
    required this.holidayForMonthDate,
    required this.holidayOn,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      holidayID: json['holiday_ID'] ?? 0,
      eventName: json['holidayName'] ?? '',
      holidayForMonthDate: json['holidayForMonthDate'] ?? '',
      holidayOn: json['holiday_On'] ?? '',
    );
  }
}
