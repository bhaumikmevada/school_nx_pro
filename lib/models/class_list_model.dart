// To parse this JSON data, do
//
//     final classListModel = classListModelFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

ClassListModel classListModelFromJson(String str) => ClassListModel.fromJson(json.decode(str));

String classListModelToJson(ClassListModel data) => json.encode(data.toJson());

class ClassListModel {
  bool success;
  List<Datum> data;

  ClassListModel({
    required this.success,
    required this.data,
  });

  factory ClassListModel.fromJson(Map<String, dynamic> json) => ClassListModel(
    success: json["success"],
    data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  int classId;
  String className;
  List<SubClass> subClasses;

  Datum({
    required this.classId,
    required this.className,
    required this.subClasses,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    classId: json["classId"],
    className: json["className"],
    subClasses: List<SubClass>.from(json["subClasses"].map((x) => SubClass.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "classId": classId,
    "className": className,
    "subClasses": List<dynamic>.from(subClasses.map((x) => x.toJson())),
  };
}

class SubClass {
  int subClassId;
  String subClassName;

  SubClass({
    required this.subClassId,
    required this.subClassName,
  });

  factory SubClass.fromJson(Map<String, dynamic> json) => SubClass(
    subClassId: json["subClassId"],
    subClassName: json["subClassName"],
  );

  Map<String, dynamic> toJson() => {
    "subClassId": subClassId,
    "subClassName": subClassName,
  };
}
