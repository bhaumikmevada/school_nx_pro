class StreamModel {
  final int? streamId;
  final String? streamName;

  StreamModel({
    required this.streamId,
    required this.streamName,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      streamId: json["streamId"],
      streamName: json["streamName"],
    );
  }
}
