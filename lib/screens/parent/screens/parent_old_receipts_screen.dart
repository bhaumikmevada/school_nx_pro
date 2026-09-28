import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_nx_pro/utils/ConstantUtils.dart';
import '../../../utils/api_urls.dart';
import '../../../utils/my_sharepreferences.dart';

class ParentOldReceiptsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentEmail;
  final String financialYear;

  const ParentOldReceiptsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentPhone,
    required this.studentEmail,
    required this.financialYear,
  });

  @override
  State<ParentOldReceiptsScreen> createState() =>
      _ParentOldReceiptsScreenState();
}

class _ParentOldReceiptsScreenState extends State<ParentOldReceiptsScreen>
    implements PayUCheckoutProProtocol {
  bool loading = true;
  Map<String, dynamic>? data;
  final TextEditingController payAmountController = TextEditingController();
  late final String _sessionYear;
  List<Map<String, dynamic>> receipts = [];

  // PayU CheckoutPro SDK instance
  late PayUCheckoutProFlutter _payUCheckoutPro;

  // Payment ke dauraan amount track karne ke liye, taaki PayU ke
  // callbacks (jo alag se aate hain) ise use kar sake.
  double _paymentAmount = 0;

  @override
  void initState() {
    super.initState();
    _sessionYear = _deriveSessionYear();
    _payUCheckoutPro = PayUCheckoutProFlutter(this);
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
      "${ApiUrls.baseUrl}fees/my?studentId=${widget.studentId}&"
          "sessionYear=${widget.financialYear}&paymentAmount=$probeAmount&subAmount=$probeAmount",
    );

    debugPrint(
      "payload ProcessPayment url : ${ApiUrls.baseUrl}fees/my?studentId=${widget.studentId}&"
          "sessionYear=${widget.financialYear}&paymentAmount=$probeAmount&subAmount=$probeAmount",
    );

    try {
      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint("payload ProcessPayment response : ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;

        // Handle both nested {"success":true,"data":{...}} and flat responses
        final Map<String, dynamic>? payload;
        if (decoded['data'] is Map<String, dynamic>) {
          payload = Map<String, dynamic>.from(decoded['data'] as Map);
        } else if (decoded.containsKey('feeDetails') ||
            decoded.containsKey('totalDue')) {
          payload = decoded;
        } else {
          payload = null;
        }

        setState(() {
          data = payload;
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
      setState(() {
        loading = false;
        data = null;
      });
      _showSnack("Error: $e");
    }
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
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
        "${ApiUrls.baseUrl}school-fees/process-payment/${widget.studentId}"
            "?sessionYear=${widget.financialYear}&paymentAmount=$formattedAmount"
    );
  }

  String _extractTransactionId(String? paymentUrl) {
    if (paymentUrl == null) {
      return "TXN${DateTime.now().millisecondsSinceEpoch}";
    }
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

    final feeDetailsRaw = currentData['feeDetails'];
    final feeDetails = <Map<String, dynamic>>[];

    if (feeDetailsRaw is List) {
      for (final item in feeDetailsRaw) {
        if (item is Map) {
          feeDetails.add(Map<String, dynamic>.from(item));
        }
      }
    }

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

  String _generatePayUTxnId() {
    final rand = Random();
    return 'TXN${DateTime.now().millisecondsSinceEpoch}${rand.nextInt(9999)}';
  }

  /// Ab yaha se seedha PayU CheckoutPro khulta hai — koi webview nahi,
  /// koi custom payment-link backend call nahi. PayU ka apna checkout
  /// screen UPI/Card/NetBanking sab khud dikhata hai.
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
      _showSnack(
        "Amount cannot exceed total due (₹${totalDue.toStringAsFixed(2)})",
      );
      return;
    }

    _paymentAmount = amount;

    // Student ki details widget se hi already aati hain (constructor params)
    String studentEmail = widget.studentEmail.trim();
    if (studentEmail.isEmpty || studentEmail == "N/A") {
      studentEmail = "parent@example.com";
    }

    String studentPhone = widget.studentPhone.trim();
    if (studentPhone.isEmpty || studentPhone == "N/A" || studentPhone.length < 10) {
      studentPhone = "9999999999";
    }

    String studentName = widget.studentName.trim();
    if (studentName.isEmpty || studentName == "N/A") {
      studentName = "Student";
    }

    final txnId = _generatePayUTxnId();

    final Map<String, dynamic> payUPaymentParams = {
      PayUPaymentParamKey.key: payUMerchantKey,
      PayUPaymentParamKey.amount: amount.toStringAsFixed(2),
      PayUPaymentParamKey.productInfo: "School Fees",
      PayUPaymentParamKey.firstName: studentName,
      PayUPaymentParamKey.email: studentEmail,
      PayUPaymentParamKey.phone: studentPhone,
      PayUPaymentParamKey.transactionId: txnId,
      PayUPaymentParamKey.environment: payUEnvironment,
      PayUPaymentParamKey.android_surl: payUAndroidSurl,
      PayUPaymentParamKey.android_furl: payUAndroidFurl,
      PayUPaymentParamKey.ios_surl: payUIosSurl,
      PayUPaymentParamKey.ios_furl: payUIosFurl,
      PayUPaymentParamKey.userCredential: "${payUMerchantKey}:$studentEmail",
    };

    final Map<String, dynamic> payUCheckoutProConfig = {
      PayUCheckoutProConfigKeys.merchantName: "School Fees",
      PayUCheckoutProConfigKeys.merchantLogo: "",
      PayUCheckoutProConfigKeys.primaryColor: "#512DA8",
      PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: true,
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen: true,
    };

    try {
      _payUCheckoutPro.openCheckoutScreen(
        payUPaymentParams: payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      );
    } catch (e, stackTrace) {
      log("PayU checkout open failed: $e", name: '_initiatePayment');
      log(stackTrace.toString(), name: '_initiatePayment stack');
      _showSnack("Unable to start payment. Please try again.", color: Colors.red);
    }
  }

  // -----------------------------------------------------------------
  // PayUCheckoutProProtocol callbacks
  // -----------------------------------------------------------------

  @override
  void generateHash(Map response) async {
    final hashName = response['hashName'];
    final hashString = response['hashString'];
    String generatedHash = '';
    final token = await MySharedPreferences.instance.getStringValue("token") ?? "";

    try {
      final res = await http.post(
        Uri.parse(payUHashGenerationApiUrl),
        headers: {
          'Content-Type': 'application/json',
          // Ngrok free-tier ke warning page ko bypass karne ke liye zaroori
          'ngrok-skip-browser-warning': 'true',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'hashName': hashName,
          'hashString': hashString,
        }),
      );

      log("Hash API response [$hashName]: ${res.statusCode} -> ${res.body}", name: 'generateHash');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        generatedHash = data['hash'] ?? '';
      } else {
        log("Hash API failed: ${res.statusCode} ${res.body}", name: 'generateHash');
      }
    } catch (e, stackTrace) {
      log("generateHash error: $e", name: 'generateHash');
      log(stackTrace.toString(), name: 'generateHash stack');
    }

    // Chahe success ho ya fail, SDK ko hamesha response bhejna zaroori hai —
    // warna SDK stuck reh jata hai.
    final Map<String, String> hashResponse = {hashName: generatedHash};
    _payUCheckoutPro.hashGenerated(hash: hashResponse);
  }

  @override
  void onPaymentSuccess(dynamic response) async {
    log("PayU Success: $response", name: 'onPaymentSuccess');

    const paymentMode = "PayU";

    if (mounted) setState(() => loading = true);
    
    try {
      final uri = _buildPaymentLinkUri(_paymentAmount, paymentMode);
      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";

      final apiResponse = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"paymentMode": paymentMode}),
      );

      debugPrint("paymentLink url :${uri.path.toString()}");
      debugPrint("payment Link Response : ${apiResponse.body}");
      if (!mounted) return;

      setState(() => loading = false);

      if (apiResponse.statusCode != 200) {
        _showSnack(
          "Unable to start payment (${apiResponse.statusCode})",
          color: Colors.red,
        );
        return;
      }

      final decoded = json.decode(apiResponse.body) as Map<String, dynamic>;
      final paymentUrl = decoded["data"]?["paymentUrl"]?.toString() ?? "";
      debugPrint("payment Link response : $decoded");
      if (paymentUrl.isEmpty) {
        _showSnack("Payment link not available", color: Colors.red);
        return;
      }
    } catch (e, stackTrace) {
      log("Backend payment notify failed: $e", name: 'onPaymentSuccess');
      log(stackTrace.toString(), name: 'onPaymentSuccess stack');
      if (mounted) setState(() => loading = false);
      _showSnack("Unable to confirm payment with server.", color: Colors.red);
      return;
    }

    final txnId = _extractTransactionId(response?.toString());

    // await generateReceipt(
    //   studentName: widget.studentName,
    //   amount: _paymentAmount,
    //   transactionId: txnId,
    //   paymentMode: "PayU",
    //   date: DateTime.now(),
    // );

    _applyLocalPayment(_paymentAmount);
    payAmountController.clear();

    if (mounted) {
      setState(() {
        receipts.insert(0, {
          "studentName": widget.studentName,
          "amount": _paymentAmount,
          "txnId": txnId,
          "paymentMode": "PayU",
          "date": DateTime.now().toString(),
        });
      });
    }

    _showSnack("✅ Payment Successful!", color: Colors.green);
    await fetchFeeData();
  }

  @override
  void onPaymentFailure(dynamic response) {
    log("PayU Failure: $response", name: 'onPaymentFailure');
    _showSnack("❌ Payment Failed!", color: Colors.red);
  }

  @override
  void onPaymentCancel(Map? response) {
    log("PayU Cancelled: $response", name: 'onPaymentCancel');
    _showSnack("Payment cancelled", color: Colors.orange);
  }

  @override
  void onError(Map? response) {
    log("PayU Error: $response", name: 'onError');
    _showSnack("Something went wrong. Please try again.", color: Colors.red);
  }

  @override
  void onApiError(Map? response) {
    log("PayU API Error: $response", name: 'onApiError');
    _showSnack("Payment API error. Please try again.", color: Colors.red);
  }

  @override
  void onCheckoutProInitializeFailure(Map? response) {
    log("PayU init failure: $response", name: 'onCheckoutProInitializeFailure');
    _showSnack("Unable to start payment. Please try again.", color: Colors.red);
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
                ),
              ],
            ),
          );
        },
      ),
    );

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
    // Safe extraction of feeDetails
    final feeDetailsRaw = data?['feeDetails'];
    final List<Map<String, dynamic>> feeDetails = [];

    if (feeDetailsRaw is List) {
      for (final item in feeDetailsRaw) {
        if (item is Map) {
          feeDetails.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final totalDue = data?['totalDue'] ?? 0;
    final totalInvoice = data?['totalInvoice'] ?? 0;

    if (feeDetails.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "No fee details available",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DataTable(
          border: TableBorder.all(color: Colors.black26),
          headingRowColor: MaterialStateColor.resolveWith(
                (states) => Colors.green.shade100,
          ),
          columns: const [
            DataColumn(label: Text("Fee Type")),
            DataColumn(label: Text("Net Due")),
            DataColumn(label: Text("Total Invoice")),
            DataColumn(label: Text("Session Year")),
          ],
          rows: [
            ...feeDetails.map(
                  (item) => DataRow(
                cells: [
                  DataCell(Text(item['feeType']?.toString() ?? "-")),
                  DataCell(Text(item['netDue']?.toString() ?? "0")),
                  DataCell(Text(item['totalInvoice']?.toString() ?? "0")),
                  DataCell(Text(item['sessionYear']?.toString() ?? "-")),
                ],
              ),
            ),
            DataRow(
              color: MaterialStateColor.resolveWith(
                    (states) => Colors.grey.shade200,
              ),
              cells: [
                const DataCell(
                  Text(
                    "Total",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    totalDue.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    totalInvoice.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataCell(Text("")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomSection() {
    final totalDue = data?['totalDue'] ?? 0;

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
                    const Text(
                      "Online Pay Amount",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
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
                    const Text(
                      "Total Due",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
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
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
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
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: _initiatePayment,
              child: const Text(
                "Pay Now",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 30),
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
                "Txn: ${r['txnId']}\n${r['paymentMode']} | ${r['date'].toString().split('.')[0]}",
              ),
              leading: const Icon(Icons.receipt_long, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}