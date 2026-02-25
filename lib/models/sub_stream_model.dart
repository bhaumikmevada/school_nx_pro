class SubStreamModel {
  final int? subStreamId;
  final String? subStreamName;

  SubStreamModel({
    required this.subStreamId,
    required this.subStreamName,
  });

  factory SubStreamModel.fromJson(Map<String, dynamic> json) {
    return SubStreamModel(
      subStreamId: json["subStreamId"] ?? 0,
      subStreamName: json["subStreamName"] ?? "N/A",
    );
  }
}
