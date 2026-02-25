class TermModel {
  final int termId;
  final String termName;

  TermModel({
    required this.termId,
    required this.termName,
  });

  factory TermModel.fromJson(Map<String, dynamic> json) {
    return TermModel(
      termId: json['termId'],
      termName: json['termName'] ?? 'Unknown',
    );
  }
}

class ExamModel {
  final int examId;
  final String examName;

  ExamModel({
    required this.examId,
    required this.examName,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      examId: json['examId'],
      examName: json['examName'] ?? 'Unknown',
    );
  }
}
