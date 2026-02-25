class ResultModel {
  final String studentId;
  final String studentName;
  final String termName;
  final String examName;
  final List<Subject> subjects;

  ResultModel({
    required this.studentId,
    required this.studentName,
    required this.termName,
    required this.examName,
    required this.subjects,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName'] ?? 'N/A',
      termName: json['termName']?.toString() ?? 'N/A',
      examName: json['examName']?.toString() ?? 'N/A',
      subjects: (json['subjects'] as List?)
              ?.map((subjectJson) => Subject.fromJson(subjectJson))
              .toList() ??
          [],
    );
  }
}

class Subject {
  final String subjectName;
  final int marksObtained;
  final int maximumMarks;
  final String gradeObtained;

  Subject({
    required this.subjectName,
    required this.marksObtained,
    required this.maximumMarks,
    required this.gradeObtained,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectName: json['subjectName'] ?? "-",
      marksObtained: json['marksObtained'] ?? 0,
      maximumMarks: json['maximumMarks'] ?? 0,
      gradeObtained: json['gradeObtained'] ?? '',
    );
  }
}
