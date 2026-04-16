import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/my_sharepreferences.dart';
import '../employee/screens/employee_dashboard.dart';

class HomeworkScreen extends StatefulWidget {
  final UserType userType;
  const HomeworkScreen({super.key, required this.userType});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  List<dynamic> homeworkList = [];
  bool isLoading = false;

  // Dialog fields
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedSubject;
  File? attachmentFile;

  List<dynamic> subjects = [];

  final fromDateFormat = DateFormat('dd-MM-yyyy');
  final toDateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    fetchSubjects();
    fetchHomeworkList();
  }

  // ================== FETCH HOMEWORK LIST ==================
  Future<void> fetchHomeworkList() async {
    setState(() => isLoading = true);
    String? allottedTeacherId =
    await MySharedPreferences.instance.getStringValue("allottedTeacherId");
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

    try {
      final response = await http.get(
        Uri.parse(
          "${ApiUrls.baseUrl}HomeworkUpload1/list?instituteId=$instituteId&allotTeacherId=$allottedTeacherId",
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> tempList = [];

        if (jsonData is Map<String, dynamic>) {
          if (jsonData['data'] is List) {
            tempList = jsonData['data'];
          } else if (jsonData['result'] is List) {
            tempList = jsonData['result'];
          } else if (jsonData['homework'] is List) {
            tempList = jsonData['homework'];
          }
        } else if (jsonData is List) {
          tempList = jsonData;
        }

        setState(() => homeworkList = tempList);
      }
    } catch (e) {
      debugPrint("Error fetching homework list: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================== FETCH SUBJECTS ==================
  Future<void> fetchSubjects() async {

    try {

      String? instituteId =
          await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
      final response = await http.get(
        Uri.parse("${ApiUrls.baseUrl}Subject?instituteId=$instituteId"),
      );
      if (response.statusCode == 200) {
        setState(() => subjects = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
    }
  }

  Future<void> pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => attachmentFile = File(result.files.single.path!));
    }
  }

  // ================== ADD HOMEWORK DIALOG ==================
  Future<void> addHomeworkDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    fromDate = null;
    toDate = null;
    selectedSubject = null;
    attachmentFile = null;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isSaving = false;

            return AlertDialog(
              title: const Text("Add Homework"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: isSaving ? null : () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) setStateDialog(() => fromDate = picked);
                      },
                      child: Text(
                        fromDate == null ? "Select From Date" : "From: ${fromDateFormat.format(fromDate!)}",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: isSaving ? null : () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) setStateDialog(() => toDate = picked);
                      },
                      child: Text(
                        toDate == null ? "Select To Date" : "To: ${toDateFormat.format(toDate!)}",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Subject"),
                      value: selectedSubject,
                      items: subjects.map((s) => DropdownMenuItem<String>(
                        value: s["subjectId"]?.toString(),
                        child: Text(s["subjectName"]?.toString() ?? ''),
                      )).toList(),
                      onChanged: isSaving ? null : (val) => setStateDialog(() => selectedSubject = val),
                    ),
                    TextField(
                      controller: titleCtrl,
                      enabled: !isSaving,
                      decoration: const InputDecoration(labelText: "Homework Title"),
                    ),
                    TextField(
                      controller: descCtrl,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                        await pickAttachment();
                        setStateDialog(() {});
                      },
                      child: Text(
                        attachmentFile == null
                            ? "Pick Attachment"
                            : "Attachment: ${attachmentFile!.path.split('/').last}",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty ||
                        selectedSubject == null ||
                        fromDate == null ||
                        toDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }

                    setStateDialog(() => isSaving = true);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white,)),
                    );

                    try {
                      final uri = Uri.parse("${ApiUrls.baseUrl}HomeworkUpload1/add");

                      var request = http.MultipartRequest('POST', uri);

                      request.fields['instituteId'] = '10085';
                      request.fields['subjectId'] = selectedSubject!;
                      request.fields['homeWorkName'] = titleCtrl.text.trim();
                      request.fields['homeWorkDescription'] = descCtrl.text.trim();
                      request.fields['homeWorkDate'] = DateFormat('dd-MM-yyyy').format(fromDate!);
                      request.fields['homeWorkDueOnDate'] = DateFormat('dd-MM-yyyy').format(toDate!);
                      request.fields['allotTeacherId'] = '50069';

                      debugPrint("attachmentFile : ${attachmentFile?.path}");

                      if (attachmentFile != null) {
                        request.files.add(await http.MultipartFile.fromPath(
                          'file',
                          attachmentFile!.path,
                          filename: attachmentFile!.path.split('/').last,
                        ));
                      }

                      final streamedResponse = await request.send();
                      final response = await http.Response.fromStream(streamedResponse);

                      debugPrint("Add Response: ${response.statusCode} - ${response.body}");

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                          Navigator.of(dialogContext).pop();
                          await fetchHomeworkList();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Homework added successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        throw Exception("Failed: ${response.body}");
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to add homework: $e")),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setStateDialog(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        title: Text(
          "Home Work",
          style: boldBlack.copyWith(fontSize: 18),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmployeeDashboard(
                  institutes: [], children: [], loginData: {},
                ),
              ),
            );
          },
          child: const Icon(Icons.arrow_back, size: 25, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeDashboard(
                    institutes: [], children: [], loginData: {},
                  ),
                ),
              );
            },
            icon: Container(
              height: 35,
              width: 35,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addHomeworkDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : homeworkList.isEmpty
          ? const Center(child: Text("No Homework Found"))
          : RefreshIndicator(
        onRefresh: fetchHomeworkList,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: homeworkList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _HomeworkCardWidget(homework: homeworkList[index]);
          },
        ),
      ),
    );
  }
}

// ================== CARD WITH VIEW ATTACHMENT API ==================
class _HomeworkCardWidget extends StatelessWidget {
  final dynamic homework;

  const _HomeworkCardWidget({required this.homework});

  @override
  Widget build(BuildContext context) {
    final headerColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purple Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    homework['subjectName']?.toString() ?? homework['subject']?.toString() ?? 'Subject',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Utils.convertDateFormat(inputDate: homework['homeWorkDate']?.toString() ?? homework['fromDate']?.toString() ?? '',
                      inputFormat: "yyyy-MM-dd'T'HH:mm:ss", outputFormat: "dd/MM/yyyy"),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // White Body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Title", homework['homeWorkName']?.toString() ?? homework['title']?.toString() ?? '-'),
                _infoRow("Due On", homework['homeWorkDueOnDate']?.toString() ?? homework['toDate']?.toString() ?? '-'),
                _attachmentRow(context, homework),
                _infoRow("Description", homework['homeWorkDescription']?.toString() ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text("$label :", style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 4,
            child: Text(value.isEmpty ? "-" : value, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ================== VIEW ATTACHMENT - CALL DOWNLOAD API ==================
  Widget _attachmentRow(BuildContext context, dynamic hw) {
    final String? homeWorkId = hw['homeWorkId']?.toString();

    // If no homeworkId or attachment, show "-"
    if (homeWorkId == null || homeWorkId.isEmpty) {
      return _infoRow("Attachment", "-");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 2,
            child: Text("Attachment :", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () async {
                final downloadUrl = "${ApiUrls.baseUrl}HomeworkUpload1/download/$homeWorkId?homeworkId=$homeWorkId";

                final uri = Uri.parse(downloadUrl);

                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not open attachment")),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error opening file: $e")),
                    );
                  }
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "📁 View Attachment",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}