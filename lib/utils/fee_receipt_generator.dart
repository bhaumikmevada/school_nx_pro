import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateFeeReceipt({
  required String studentName,
  required double amount,
  required String transactionId,
  required String paymentMode,
  required DateTime paymentDate,
  String schoolName = "ABC School",
}) async {
  final pdf = pw.Document();
  final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(paymentDate);

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "$schoolName - Fees Receipt",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Student Name: $studentName"),
              pw.Text("Payment Mode: $paymentMode"),
              pw.Text("Transaction ID: $transactionId"),
              pw.Text("Date: $formattedDate"),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                "Amount Paid: ₹${amount.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  "✅ Payment Successful",
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.green,
                  ),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Authorized Signatory"),
              ),
            ],
          ),
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

