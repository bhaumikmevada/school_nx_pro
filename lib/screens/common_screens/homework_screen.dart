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

  // NOTE: classesList is kept as List<dynamic> (raw map data straight from the
  // "classes" API: {classId, className, subClasses:[{subClassId, subClassName}]}).
  // I removed the ClassListModel typing since the model file wasn't shared —
  // if you already have a proper model with these fields, you can swap this
  // back to List<ClassListModel> and update the two spots marked below.
  List<dynamic> classesList = [];

  bool isLoading = false;

  // Dialog fields
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedSubject;
  String? selectedClass;      // holds classId
  String? selectedSubClass;   // holds subClassId
  List<dynamic> subClassOptions = []; // subClasses of the currently selected class
  File? attachmentFile;

  List<dynamic> subjects = [];

  final fromDateFormat = DateFormat('dd-MM-yyyy');
  final toDateFormat = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    fetchSubjects();
    fetchHomeworkList();
    fetchClasses();
  }

  // ================== FETCH CLASSES (with subclasses) ==================
  Future<void> fetchClasses() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

    try {
      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";

      final response = await http.get(
        Uri.parse(
          "${ApiUrls.baseUrl}${ApiUrls.classesList}?instituteId=$instituteId",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("classes url : ${ApiUrls.baseUrl}${ApiUrls.classesList}?instituteId=$instituteId");
      debugPrint("classes response : ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List<dynamic> tempList = [];

        if (jsonData is Map<String, dynamic>) {
          if (jsonData['data'] is List) {
            tempList = jsonData['data'];
          }
        } else if (jsonData is List) {
          tempList = jsonData;
        }

        setState(() => classesList = tempList);
      }
    } catch (e) {
      debugPrint("Error fetching classes list: $e");
    }
  }

  // ================== DELETE HOMEWORK ==================
  Future<void> deleteHomework(BuildContext context, String homeworkId) async {
    // show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";

      final response = await http.delete(
        Uri.parse(
          "${ApiUrls.baseUrl}homework-upload1/delete/$homeworkId",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("deleteHomework url : ${ApiUrls.baseUrl}homework-upload1/delete/$homeworkId");
      debugPrint("deleteHomework response : ${response.body}");

      // close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          // refresh list so the deleted entry is removed
          await fetchHomeworkList();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(jsonData['message']?.toString() ?? "Homework deleted successfully"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(jsonData['message']?.toString() ?? "Failed to delete homework")),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete homework")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error delete homework : $e");
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting homework: $e")),
        );
      }
    }
  }

  // ================== FETCH HOMEWORK LIST ==================
  Future<void> fetchHomeworkList() async {
    setState(() => isLoading = true);
    String? allottedTeacherId =
    await MySharedPreferences.instance.getStringValue("allottedTeacherId");
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

    try {
      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";

      debugPrint("selectedSubject : $selectedSubject");

      final response = await http.get(
        Uri.parse(
          "${ApiUrls.baseUrl}homework/list?instituteId=$instituteId&subjectId=$selectedSubject&allotTeacherId=$allottedTeacherId",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("homework url : ${ApiUrls.baseUrl}homework/list?instituteId=$instituteId&subjectId=$selectedSubject&allotTeacherId=$allottedTeacherId");
      debugPrint("homework response : ${response.body}");
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
      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";
      String? instituteId =
          await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
      final response = await http.get(
        Uri.parse("${ApiUrls.baseUrl}subject?instituteId=$instituteId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("homework subject response : ${response.body}");

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

  // Helper: returns the subClasses list for a given classId from classesList
  List<dynamic> _getSubClassesForClass(String? classId) {
    if (classId == null) return [];
    final matched = classesList.where((c) => c['classId'].toString() == classId).toList();
    if (matched.isEmpty) return [];
    return (matched.first['subClasses'] as List<dynamic>?) ?? [];
  }

  // ================== ADD HOMEWORK DIALOG ==================
  Future<void> addHomeworkDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    fromDate = null;
    toDate = null;
    selectedSubject = null;
    selectedClass = null;
    selectedSubClass = null;
    subClassOptions = [];
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

                    // ---------------- SUBJECT DROPDOWN ----------------
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Subject"),
                      value: selectedSubject,
                      items: subjects.map((s) => DropdownMenuItem<String>(
                        value: s["subjectId"]?.toString(),
                        child: Text(s["subjectName"]?.toString() ?? ''),
                      )).toList(),
                      onChanged: isSaving ? null : (val) => setStateDialog(() => selectedSubject = val),
                    ),
                    const SizedBox(height: 8),

                    // ---------------- CLASS DROPDOWN ----------------
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Class"),
                      value: selectedClass,
                      items: classesList.map((c) => DropdownMenuItem<String>(
                        value: c["classId"]?.toString(),
                        child: Text(c["className"]?.toString() ?? ''),
                      )).toList(),
                      onChanged: isSaving ? null : (val) {
                        setStateDialog(() {
                          selectedClass = val;
                          // reset subclass whenever class changes
                          selectedSubClass = null;
                          subClassOptions = _getSubClassesForClass(val);
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // ---------------- SUBCLASS DROPDOWN (depends on class) ----------------
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Sub Class",
                        hintText: selectedClass == null ? "Select class first" : null,
                      ),
                      value: selectedSubClass,
                      items: subClassOptions.map((sc) => DropdownMenuItem<String>(
                        value: sc["subClassId"]?.toString(),
                        child: Text(sc["subClassName"]?.toString() ?? ''),
                      )).toList(),
                      // disabled until a class is selected and it has subclasses
                      onChanged: (isSaving || selectedClass == null || subClassOptions.isEmpty)
                          ? null
                          : (val) => setStateDialog(() => selectedSubClass = val),
                    ),
                    const SizedBox(height: 8),

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
                    // ---------------- VALIDATION ----------------
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

                    if (selectedClass == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select class")),
                      );
                      return;
                    }

                    if (selectedSubClass == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select sub class")),
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
                      final uri = Uri.parse("${ApiUrls.baseUrl}homework-upload1/add");
                      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";
                      String? instituteUserId = await MySharedPreferences.instance.getStringValue("employeeUserId");
                      String? allottedTeacherId = await MySharedPreferences.instance.getStringValue("allottedTeacherId");
                      String instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

                      debugPrint("add homework url : ${ApiUrls.baseUrl}homework-upload1/add");
                      debugPrint("add homework instituteUserId : $instituteUserId, allottedTeacherId : $allottedTeacherId");

                      var request = http.MultipartRequest('POST', uri);
                      request.headers['Authorization'] = 'Bearer $token';
                      request.fields['instituteId'] = instituteId;
                      request.fields['subjectId'] = selectedSubject!;
                      request.fields['classId'] = selectedClass!;
                      request.fields['subClassId'] = selectedSubClass!;
                      request.fields['homeWorkName'] = titleCtrl.text.trim();
                      request.fields['homeWorkDescription'] = descCtrl.text.trim();
                      request.fields['homeWorkDate'] = DateFormat('dd-MM-yyyy').format(fromDate!);
                      request.fields['homeWorkDueOnDate'] = DateFormat('dd-MM-yyyy').format(toDate!);
                      request.fields['allotTeacherId'] = allottedTeacherId ?? "";
                      request.fields['instituteUserId'] = "90563";

                      debugPrint("attachmentFile : ${attachmentFile?.path}");
                      debugPrint("request field add homework : ${request.fields}");

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
                        // close loader
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                        // close the add-homework dialog
                        Navigator.of(dialogContext).pop();

                        // refresh list in background
                        fetchHomeworkList();

                        // show success message on the main screen context
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Homework added successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        return; // dialog + its StatefulBuilder are gone now, don't touch setStateDialog below
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
                      // dialog is still open in the failure case, so it's safe
                      // to re-enable the Save button
                      setStateDialog(() => isSaving = false);
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
            return _HomeworkCardWidget(
              homework: homeworkList[index],
              onDelete: (homeworkId) => deleteHomework(context, homeworkId),
            );
          },
        ),
      ),
    );
  }
}

// ================== CARD WITH VIEW ATTACHMENT API ==================
class _HomeworkCardWidget extends StatelessWidget {
  final dynamic homework;
  final Function(String homeworkId) onDelete;

  const _HomeworkCardWidget({
    required this.homework,
    required this.onDelete,
  });

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

                Container(
                  height: 1,
                  color: AppColors.colorDADADA,
                  margin: const EdgeInsets.only(bottom: 5),
                ),

                Container(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      final String? homeWorkId = homework['homeWorkId']?.toString();
                      if (homeWorkId == null || homeWorkId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid homework id")),
                        );
                        return;
                      }
                      Utils.showAlertDialog(
                        context,
                        title: "Delete Homework",
                        message: "Are you sure you want to delete this homework?",
                        okButtonText: "Yes",
                        cancelButtonText: "No",
                        onOkPressed: () {
                          onDelete(homeWorkId);
                        },
                      );
                    },
                    child: const Icon(Icons.delete_forever, color: Colors.red,),
                  ),
                )
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
                final downloadUrl = "${ApiUrls.baseUrl}homework-upload1/download/$homeWorkId";
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