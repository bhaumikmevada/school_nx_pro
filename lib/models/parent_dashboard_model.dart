// To parse this JSON data, do
//
//     final studentDetailsModel = studentDetailsModelFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

StudentDetailsModel studentDetailsModelFromJson(String str) => StudentDetailsModel.fromJson(json.decode(str));

String studentDetailsModelToJson(StudentDetailsModel data) => json.encode(data.toJson());

class StudentDetailsModel {
  ProfileData profileData;
  AttendanceData attendanceData;
  List<NextHolidayDatum> nextHolidayData;
  List<dynamic> todaysHomeworkData;
  List<EventsDatum> eventsData;
  FeeData feeData;

  StudentDetailsModel({
    required this.profileData,
    required this.attendanceData,
    required this.nextHolidayData,
    required this.todaysHomeworkData,
    required this.eventsData,
    required this.feeData,
  });

  factory StudentDetailsModel.fromJson(Map<String, dynamic> json) => StudentDetailsModel(
    profileData: ProfileData.fromJson(json["profileData"]),
    attendanceData: AttendanceData.fromJson(json["attendanceData"]),
    nextHolidayData: List<NextHolidayDatum>.from(json["nextHolidayData"].map((x) => NextHolidayDatum.fromJson(x))),
    todaysHomeworkData: List<dynamic>.from(json["todaysHomeworkData"].map((x) => x)),
    eventsData: List<EventsDatum>.from(json["eventsData"].map((x) => EventsDatum.fromJson(x))),
    feeData: FeeData.fromJson(json["feeData"]),
  );

  Map<String, dynamic> toJson() => {
    "profileData": profileData.toJson(),
    "attendanceData": attendanceData.toJson(),
    "nextHolidayData": List<dynamic>.from(nextHolidayData.map((x) => x.toJson())),
    "todaysHomeworkData": List<dynamic>.from(todaysHomeworkData.map((x) => x)),
    "eventsData": List<dynamic>.from(eventsData.map((x) => x.toJson())),
    "feeData": feeData.toJson(),
  };
}

class AttendanceData {
  List<Last7Day> last7Days;
  MonthlySummary monthlySummary;

  AttendanceData({
    required this.last7Days,
    required this.monthlySummary,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
    last7Days: List<Last7Day>.from(json["last7Days"].map((x) => Last7Day.fromJson(x))),
    monthlySummary: MonthlySummary.fromJson(json["monthlySummary"]),
  );

  Map<String, dynamic> toJson() => {
    "last7Days": List<dynamic>.from(last7Days.map((x) => x.toJson())),
    "monthlySummary": monthlySummary.toJson(),
  };
}

class Last7Day {
  String date;
  String status;

  Last7Day({
    required this.date,
    required this.status,
  });

  factory Last7Day.fromJson(Map<String, dynamic> json) => Last7Day(
    date: json["date"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "date": date,
    "status": status,
  };
}

class MonthlySummary {
  int present;
  int absent;
  int totalDays;

  MonthlySummary({
    required this.present,
    required this.absent,
    required this.totalDays,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
    present: json["present"],
    absent: json["absent"],
    totalDays: json["totalDays"],
  );

  Map<String, dynamic> toJson() => {
    "present": present,
    "absent": absent,
    "totalDays": totalDays,
  };
}

class EventsDatum {
  int eventId;
  String eventTitle;
  String eventDate;

  EventsDatum({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
  });

  factory EventsDatum.fromJson(Map<String, dynamic> json) => EventsDatum(
    eventId: json["eventId"],
    eventTitle: json["eventTitle"],
    eventDate: json["eventDate"],
  );

  Map<String, dynamic> toJson() => {
    "eventId": eventId,
    "eventTitle": eventTitle,
    "eventDate": eventDate,
  };
}

class FeeData {
  int totalDue;
  int totalInvoice;
  int paidAmount;
  int remainingAmount;
  List<FeeDetail> feeDetails;

  FeeData({
    required this.totalDue,
    required this.totalInvoice,
    required this.paidAmount,
    required this.remainingAmount,
    required this.feeDetails,
  });

  factory FeeData.fromJson(Map<String, dynamic> json) => FeeData(
    totalDue: json["totalDue"],
    totalInvoice: json["totalInvoice"],
    paidAmount: json["paidAmount"],
    remainingAmount: json["remainingAmount"],
    feeDetails: List<FeeDetail>.from(json["feeDetails"].map((x) => FeeDetail.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "totalDue": totalDue,
    "totalInvoice": totalInvoice,
    "paidAmount": paidAmount,
    "remainingAmount": remainingAmount,
    "feeDetails": List<dynamic>.from(feeDetails.map((x) => x.toJson())),
  };
}

class FeeDetail {
  String feeType;
  int netDue;
  int totalInvoice;

  FeeDetail({
    required this.feeType,
    required this.netDue,
    required this.totalInvoice,
  });

  factory FeeDetail.fromJson(Map<String, dynamic> json) => FeeDetail(
    feeType: json["feeType"],
    netDue: json["netDue"],
    totalInvoice: json["totalInvoice"],
  );

  Map<String, dynamic> toJson() => {
    "feeType": feeType,
    "netDue": netDue,
    "totalInvoice": totalInvoice,
  };
}

class NextHolidayDatum {
  int holidayId;
  String holidayDate;
  String reason;

  NextHolidayDatum({
    required this.holidayId,
    required this.holidayDate,
    required this.reason,
  });

  factory NextHolidayDatum.fromJson(Map<String, dynamic> json) => NextHolidayDatum(
    holidayId: json["holidayId"],
    holidayDate: json["holidayDate"],
    reason: json["reason"],
  );

  Map<String, dynamic> toJson() => {
    "holidayId": holidayId,
    "holidayDate": holidayDate,
    "reason": reason,
  };
}

class ProfileData {
  int userId;
  String type;
  String name;
  String mobile;
  int city;

  ProfileData({
    required this.userId,
    required this.type,
    required this.name,
    required this.mobile,
    required this.city,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    userId: json["userId"],
    type: json["type"],
    name: json["name"],
    mobile: json["mobile"],
    city: json["city"],
  );

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "type": type,
    "name": name,
    "mobile": mobile,
    "city": city,
  };
}
