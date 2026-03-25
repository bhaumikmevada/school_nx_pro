// To parse this JSON data, do
//
//     final holidayListModel = holidayListModelFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

HolidayListModel holidayListModelFromJson(String str) => HolidayListModel.fromJson(json.decode(str));

String holidayListModelToJson(HolidayListModel data) => json.encode(data.toJson());

class HolidayListModel {
  bool success;
  List<Day> days;

  HolidayListModel({
    required this.success,
    required this.days,
  });

  factory HolidayListModel.fromJson(Map<String, dynamic> json) => HolidayListModel(
    success: json["success"],
    days: List<Day>.from(json["days"].map((x) => Day.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "days": List<dynamic>.from(days.map((x) => x.toJson())),
  };
}

class Day {
  DateTime date;
  List<Holiday> holidays;

  Day({
    required this.date,
    required this.holidays,
  });

  factory Day.fromJson(Map<String, dynamic> json) => Day(
    date: DateTime.parse(json["date"]),
    holidays: List<Holiday>.from(json["holidays"].map((x) => Holiday.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    "holidays": List<dynamic>.from(holidays.map((x) => x.toJson())),
  };
}

class Holiday {
  String reason;
  List<String> images;

  Holiday({
    required this.reason,
    required this.images,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
    reason: json["reason"],
    images: List<String>.from(json["images"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "reason": reason,
    "images": List<dynamic>.from(images.map((x) => x)),
  };
}
