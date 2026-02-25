class CourseModel {
  final int? courseId;
  final String? courseName;

  CourseModel({
    required this.courseId,
    required this.courseName,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      courseId: json["courseId"],
      courseName: json["courseName"],
    );
  }
}
