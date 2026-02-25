class SchoolCircularModel {
  final int eventId;
  final String eventName;
  final DateTime eventDate;
  final String imageBase64;

  SchoolCircularModel({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.imageBase64,
  });

  factory SchoolCircularModel.fromJson(Map<String, dynamic> json) {
    return SchoolCircularModel(
      eventId: json['eventId'],
      eventName: json['eventName'],
      eventDate: DateTime.parse(json['eventDate']),
      imageBase64: json['imageBase64'] ?? "",
    );
  }
}
