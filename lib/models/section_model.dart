class SectionModel {
  final int? sectionId;
  final String? sectionName;

  SectionModel({
    required this.sectionId,
    required this.sectionName,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      sectionId: json["sectionId"],
      sectionName: json["sectionName"],
    );
  }
}
