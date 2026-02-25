class MediumModel {
  final int? mediumId;
  final String? mediumName;

  MediumModel({
    required this.mediumId,
    required this.mediumName,
  });

  factory MediumModel.fromJson(Map<String, dynamic> json) {
    return MediumModel(
      mediumId: json["mediumId"],
      mediumName: json["mediumName"],
    );
  }
}
