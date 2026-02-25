import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_nx_pro/screens/parent/screens/payment_webview_screen.dart';

class ParentOldReceiptsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentEmail;

  const ParentOldReceiptsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.studentEmail,
  });

  @override
  State<ParentOldReceiptsScreen> createState() => _ParentOldReceiptsScreenState();
}

class _ParentOldReceiptsScreenState extends State<ParentOldReceiptsScreen> {
  bool loading = true;
  Map<String, dynamic>? data;
  final TextEditingController payAmountController = TextEditingController();
  late final String _sessionYear;

  List<Map<String, dynamic>> receipts = [];

  @override
  void initState() {
    super.initState();
    _sessionYear = _deriveSessionYear();
    fetchFeeData();
  }

  String _deriveSessionYear() {
    final now = DateTime.now();
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    return "$startYear-$endYear";
  }

  Future<void> fetchFeeData() async {
    if (mounted) {
      setState(() => loading = true);
    }
    const probeAmount = "1";
    final uri = Uri.parse(
      "https://api.schoolnxpro.com/api/Payload/ProcessPayment/${widget.studentId}",
    ).replace(queryParameters: {
      "sessionYear": _sessionYear,
      "paymentAmount": probeAmount,
      "subAmount": probeAmount,
    });

    try {
      final response = await http.post(uri);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          data = decoded;
          loading = false;
        });
        payAmountController.clear();
      } else {
        setState(() {
          loading = false;
          data = null;
        });
        final responseBody = response.body.trim();
        final fallbackMessage =
            "Failed to load data: ${response.statusCode}";
        _showSnack(
          responseBody.isEmpty ? fallbackMessage : responseBody,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack("Error: $e");
    }
  }

  void _showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Uri _buildPaymentLinkUri(double amount, String paymentMode) {
    final formattedAmount = amount.toStringAsFixed(2);
    return Uri.parse(
      "https://api.schoolnxpro.com/api/SchoolFess4/ProcessPayment/${widget.studentId}",
    ).replace(queryParameters: {
      "sessionYear": _sessionYear,
      "paymentAmount": formattedAmount,
      "paymentMode": paymentMode,
    });
  }

  String _extractTransactionId(String paymentUrl) {
    final uri = Uri.tryParse(paymentUrl);
    if (uri == null) {
      return "TXN${DateTime.now().millisecondsSinceEpoch}";
    }
    final params = uri.queryParameters;
    return params["transactionId"] ??
        params["txnId"] ??
        params["orderId"] ??
        "TXN${DateTime.now().millisecondsSinceEpoch}";
  }

  double _roundTo2Decimals(double value) =>
      double.parse(value.toStringAsFixed(2));

  void _applyLocalPayment(double amount) {
    if (data == null || amount <= 0) return;

    final currentData = Map<String, dynamic>.from(data!);
    final feeDetails = (currentData['feeDetails'] as List<dynamic>? ?? [])
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    double remaining = amount;
    for (final detail in feeDetails) {
      if (remaining <= 0) break;
      final netDue = (detail['netDue'] as num?)?.toDouble() ?? 0.0;
      if (netDue <= 0) continue;
      final deduction = remaining >= netDue ? netDue : remaining;
      detail['netDue'] = _roundTo2Decimals(netDue - deduction);
      remaining -= deduction;
    }

    final totalDue = (currentData['totalDue'] as num?)?.toDouble() ?? 0.0;
    final adjustedTotalDue = totalDue - amount;
    currentData['totalDue'] = _roundTo2Decimals(
      adjustedTotalDue < 0 ? 0 : adjustedTotalDue,
    );
    currentData['feeDetails'] = feeDetails;

    setState(() {
      data = currentData;
    });
  }

  Future<void> _initiatePayment() async {
    final enteredAmount = payAmountController.text.trim();
    if (enteredAmount.isEmpty || enteredAmount == "0") {
      _showSnack("Please enter an amount");
      return;
    }

    final amount = double.tryParse(enteredAmount);
    if (amount == null || amount <= 0) {
      _showSnack("Please enter a valid amount");
      return;
    }

    final totalDue = (data?['totalDue'] as num?)?.toDouble();
    if (totalDue != null && totalDue > 0 && amount > totalDue) {
      _showSnack("Amount cannot exceed total due (₹${totalDue.toStringAsFixed(2)})");
      return;
    }

    const paymentMode = "UPI";
    setState(() => loading = true);

    try {
      final uri = _buildPaymentLinkUri(amount, paymentMode);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"paymentMode": paymentMode}),
      );

      if (!mounted) {
        return;
      }

      setState(() => loading = false);

      if (response.statusCode != 200) {
        _showSnack("Unable to start payment (${response.statusCode})",
            color: Colors.red);
        return;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final paymentUrl = decoded["paymentUrl"]?.toString() ?? "";

      if (paymentUrl.isEmpty) {
        _showSnack("Payment link not available", color: Colors.red);
        return;
      }

      final navResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(paymentUrl: paymentUrl),
        ),
      );

      if (!mounted) return;

      if (navResult == "success") {
        final txnId = _extractTransactionId(paymentUrl);
        await generateReceipt(
          studentName: widget.studentName,
          amount: amount,
          transactionId: txnId,
          paymentMode: "Online (Paytm)",
          date: DateTime.now(),
        );

        _applyLocalPayment(amount);
        payAmountController.clear();
        setState(() {
          receipts.insert(0, {
            "studentName": widget.studentName,
            "amount": amount,
            "txnId": txnId,
            "paymentMode": "Online (Paytm)",
            "date": DateTime.now().toString(),
          });
        });

        _showSnack("✅ Payment Successful!", color: Colors.green);
        await fetchFeeData();
      } else if (navResult == "failure") {
        _showSnack("❌ Payment Failed!", color: Colors.red);
      } else {
        _showSnack("Payment cancelled", color: Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack("Exception: $e", color: Colors.red);
    }
  }

  // ✅ PDF Receipt Generator
  Future<void> generateReceipt({
    required String studentName,
    required double amount,
    required String transactionId,
    required String paymentMode,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

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
                    "ABC School - Fees Receipt",
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
                pw.Text("Date: ${date.toLocal()}"),
                pw.SizedBox(height: 10),
                pw.Divider(),

                pw.Text(
                  "Amount Paid: ₹$amount",
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
                )
              ],
            ),
          );
        },
      ),
    );

    // PDF preview
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fee Details")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text("No Data Found"))
              : Column(
                  children: [
                    Expanded(child: buildFeeTable()),
                    buildBottomSection(),
                    if (receipts.isNotEmpty) buildReceiptList(),
                  ],
                ),
    );
  }

  Widget buildFeeTable() {
    final feeDetails = List<Map<String, dynamic>>.from(data!['feeDetails']);
    final totalDue = data!['totalDue'];
    final totalInvoice = data!['totalInvoice'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DataTable(
          border: TableBorder.all(color: Colors.black26),
          headingRowColor: MaterialStateColor.resolveWith(
              (states) => Colors.green.shade100),
          columns: const [
            DataColumn(label: Text("Fee Type")),
            DataColumn(label: Text("Net Due")),
            DataColumn(label: Text("Total Invoice")),
            DataColumn(label: Text("Session Year")),
          ],
          rows: feeDetails
              .map((item) => DataRow(cells: [
                    DataCell(Text(item['feeType'].toString())),
                    DataCell(Text(item['netDue'].toString())),
                    DataCell(Text(item['totalInvoice'].toString())),
                    DataCell(Text(item['sessionYear'].toString())),
                  ]))
              .toList()
            ..add(
              DataRow(
                color: MaterialStateColor.resolveWith(
                    (states) => Colors.grey.shade200),
                cells: [
                  const DataCell(Text("Total",
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(totalDue.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(totalInvoice.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  const DataCell(Text("")),
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget buildBottomSection() {
    final totalDue = data!['totalDue'];

    return Container(
      width: double.infinity,
      color: const Color(0xFFAEEBC2),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Online Pay Amount",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 5),
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: payAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Due",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 5),
                    Container(
                      height: 38,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        totalDue.toString(),
                        style: const TextStyle(
                            color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _initiatePayment,
              child: const Text(
                "Pay Now",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildReceiptList() {
    return Expanded(
      child: ListView.builder(
        itemCount: receipts.length,
        itemBuilder: (context, index) {
          final r = receipts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.green.shade50,
            child: ListTile(
              title: Text("${r['studentName']} - ₹${r['amount']}"),
              subtitle: Text(
                  "Txn: ${r['txnId']}\n${r['paymentMode']} | ${r['date'].toString().split('.')[0]}"),
              leading: const Icon(Icons.receipt_long, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
