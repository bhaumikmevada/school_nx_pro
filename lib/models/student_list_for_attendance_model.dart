class StudentListForAttendanceModel {
  final int admissionId;
  final String firstName;
  final String lastName;
  final String contactNo;
  final String fathersname;
  final String courseName;
  final String sectionName;
  final String streamName;
  final String subStreamName;

  StudentListForAttendanceModel({
    required this.admissionId,
    required this.firstName,
    required this.lastName,
    required this.contactNo,
    required this.fathersname,
    required this.courseName,
    required this.sectionName,
    required this.streamName,
    required this.subStreamName,
  });

  factory StudentListForAttendanceModel.fromJson(Map<String, dynamic> json) =>
      StudentListForAttendanceModel(
        admissionId: json["admissionId"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        contactNo: json["contactNo"],
        fathersname: json["fathersname"],
        courseName: json["courseName"],
        sectionName: json["sectionName"],
        streamName: json["streamName"],
        subStreamName: json["subStreamName"],
      );
}
