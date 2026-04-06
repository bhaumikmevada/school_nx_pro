// To parse this JSON data, do
//
//     final eventListModel = eventListModelFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

EventListModel eventListModelFromJson(String str) => EventListModel.fromJson(json.decode(str));

String eventListModelToJson(EventListModel data) => json.encode(data.toJson());

class EventListModel {
  bool success;
  int year;
  int month;
  List<Day> days;

  EventListModel({
    required this.success,
    required this.year,
    required this.month,
    required this.days,
  });

  factory EventListModel.fromJson(Map<String, dynamic> json) => EventListModel(
    success: json["success"],
    year: json["year"],
    month: json["month"],
    days: List<Day>.from(json["days"].map((x) => Day.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "year": year,
    "month": month,
    "days": List<dynamic>.from(days.map((x) => x.toJson())),
  };
}

class Day {
  DateTime date;
  List<Event> events;

  Day({
    required this.date,
    required this.events,
  });

  factory Day.fromJson(Map<String, dynamic> json) => Day(
    date: DateTime.parse(json["date"]),
    events: List<Event>.from(json["events"].map((x) => Event.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "date": "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    "events": List<dynamic>.from(events.map((x) => x.toJson())),
  };
}

class Event {
  int eventId;
  String eventName;
  String eventDate;
  int courseId;
  String courseName;
  List<String> images;

  Event({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.courseId,
    required this.courseName,
    required this.images,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    eventId: json["eventId"],
    eventName: json["eventName"],
    eventDate: json["eventDate"],
    courseId: json["courseId"],
    courseName: json["courseName"],
    images: List<String>.from(json["images"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "eventId": eventId,
    "eventName": eventName,
    "eventDate": eventDate,
    "courseId": courseId,
    "courseName": courseName,
    "images": List<dynamic>.from(images.map((x) => x)),
  };
}
