class OldReceiptModel {
  final int receiptId;
  final dynamic amount;
  final DateTime date;

  OldReceiptModel({
    required this.receiptId,
    required this.amount,
    required this.date,
  });

  factory OldReceiptModel.fromJson(Map<String, dynamic> json) {
    return OldReceiptModel(
      receiptId: json['receipt_id'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
    );
  }
}
