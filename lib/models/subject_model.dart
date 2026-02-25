class SubjectModel {
  final int subjectId;
  final String subjectName;

  SubjectModel({
    required this.subjectId,
    required this.subjectName,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
    );
  }
}
