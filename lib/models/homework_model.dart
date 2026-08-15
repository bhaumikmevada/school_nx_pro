class HomeworkModel {
  final int homeWorkId;
  final String homeWorkName;
  final String homeWorkDescription;
  final String homeWorkDate;
  final String homeWorkDueOnDate;

  HomeworkModel({
    required this.homeWorkId,
    required this.homeWorkName,
    required this.homeWorkDescription,
    required this.homeWorkDate,
    required this.homeWorkDueOnDate,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      homeWorkId: json['homeWorkId'] ?? 0,
      homeWorkName: json['homeWorkName'] ?? '',
      homeWorkDescription: json['homeWorkDescription'] ?? '',
      homeWorkDate: json['homeWorkDate'] ?? '',
      homeWorkDueOnDate: json['homeWorkDueOnDate'] ?? '',
    );
  }
}
