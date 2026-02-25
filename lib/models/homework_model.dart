class HomeworkModel {
  final int homeWorkId;
  final String homeWorkName;
  final String homeWorkDescription;
  final DateTime homeWorkDate;
  final DateTime homeWorkDueOnDate;

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
      homeWorkDate: DateTime.parse(json['homeWorkDate']),
      homeWorkDueOnDate: DateTime.parse(json['homeWorkDueOnDate']),
    );
  }
}
