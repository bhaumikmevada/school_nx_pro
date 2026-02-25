import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:school_nx_pro/provider/homework_provider.dart';
import 'package:school_nx_pro/provider/parent_homework_provider.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_dashboard.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/services/homework_sync_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeworkScreen extends StatefulWidget {
  final UserType userType;
  const HomeworkScreen({super.key, required this.userType});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  List<Map<String, dynamic>> homeworkList = [];
  List<Map<String, dynamic>> apiHomeworkList = [];
  List subjects = [];
  bool isLoading = false;
  final HomeworkSyncService _syncService = HomeworkSyncService();
  String? _studentId;

  DateTime? fromDate;
  DateTime? toDate;
  String? selectedSubject;
  File? attachmentFile;

  @override
  void initState() {
    super.initState();
    fetchSubjects();
    _syncService.initialize();
    setState(() => isLoading = true);
    _initAndLoadHomework();
  }

  /// Load homework: when studentId is available use same provider as ParentHomeworkScreen
  /// (API + local merged); otherwise fallback to local-only list.
  Future<void> _initAndLoadHomework() async {
    final studentId =
        await MySharedPreferences.instance.getStringValue("studentId") ?? '';
    if (studentId.isNotEmpty) {
      if (!mounted) return;
      final provider =
          Provider.of<HomeworkProviders>(context, listen: false);
      setState(() => isLoading = true);
      await provider.fetchHomework(studentId, forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _studentId = studentId;
        isLoading = false;
      });
      return;
    }
    // No studentId: load local list so screen is not blank; provider will merge when studentId is set later
    await loadAllHomework();
  }

  // /// 🔹 Load saved homework from SharedPreferences
  // Future<void> loadHomeworkFromLocal() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final savedData = prefs.getString("homeworkList");
  //   if (savedData != null) {
  //     setState(() {
  //       homeworkList = List<Map<String, dynamic>>.from(jsonDecode(savedData));
  //     });
  //   }
  // }

  /// 🔹 Load both Local + API homework (used when no studentId, or to refresh local state)
  Future<void> loadAllHomework() async {
    setState(() => isLoading = true);

    await loadHomeworkFromLocal();
    await fetchHomeworkFromAPI();

    // ✅ Merge API + Local (avoid duplicates by title+subject)
    final merged = {
      for (var hw in [...homeworkList, ...apiHomeworkList])
        '${hw["title"]}_${hw["subject"]}': hw
    };
    homeworkList = merged.values.toList();

    await saveHomeworkToLocal(); // keep synced

    final studentId =
        await MySharedPreferences.instance.getStringValue("studentId") ?? '';
    if (studentId.isNotEmpty && mounted) {
      final provider =
          Provider.of<HomeworkProviders>(context, listen: false);
      await provider.fetchHomework(studentId, forceRefresh: true);
      if (mounted) {
        setState(() {
          _studentId = studentId;
          isLoading = false;
        });
        return;
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// 🔹 Load saved homework from SharedPreferences
  Future<void> loadHomeworkFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString("homeworkList");
    if (savedData != null) {
      homeworkList = List<Map<String, dynamic>>.from(jsonDecode(savedData));
    }
  }

  /// 🔹 Save homework to SharedPreferences
  Future<void> saveHomeworkToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("homeworkList", jsonEncode(homeworkList));
  }

  /// 🔹 Fetch homework from API
  Future<void> fetchHomeworkFromAPI() async {
    try {
      final studentId =
          await MySharedPreferences.instance.getStringValue("studentId");
      if (studentId == null || studentId.isEmpty) {
        debugPrint("Student ID not found for homework sync");
        return;
      }
      final instituteId =
          await MySharedPreferences.instance.getStringValue("instituteId") ??
              "10085";
      final response = await http.get(
        Uri.parse(
          "https://api.schoolnxpro.com/api/Homework/Id?admissionId=$studentId&instituteId=$instituteId",
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData['data'];

        List<Map<String, dynamic>> parsed = [];
        if (data is List) {
          parsed = data.map<Map<String, dynamic>>((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final hw = Map<String, dynamic>.from(
              (map['homework'] ?? <String, dynamic>{}) as Map,
            );
            return _mapApiHomework(map, hw);
          }).toList();
        } else if (data is Map<String, dynamic>) {
          final hw = Map<String, dynamic>.from(
            (data['homework'] ?? <String, dynamic>{}) as Map<String, dynamic>,
          );
          parsed = [_mapApiHomework(data, hw)];
        }

        apiHomeworkList = parsed;
      }
    } catch (e) {
      debugPrint("API fetch error: $e");
    }
  }

  Map<String, dynamic> _mapApiHomework(
    Map<String, dynamic> container,
    Map<String, dynamic> hw,
  ) {
    final attachmentPath = hw['attachment'];
    final extensions = hw['extensions']?.toString() ?? '';
    final homeWorkId = hw['homeWorkId']?.toString() ?? '';
    final resolvedAttachment = attachmentPath ??
        (homeWorkId.isNotEmpty && extensions.isNotEmpty
            ? "https://schoolnx.com/SchoolWebsiteImages/Institute10085/HomeWork/Attachment_${homeWorkId}$extensions"
            : null);

    return {
      "subject": container['subjectName'] ?? '',
      "title": hw['homeWorkName'] ?? '',
      "description": hw['homeWorkDescription'] ?? '',
      "fromDate": hw['homeWorkDate'] ?? '',
      "toDate": hw['homeWorkDueOnDate'] ?? '',
      "attachment": resolvedAttachment,
      "extensions": extensions,
      "homeWorkId": homeWorkId,
      "subjectId": hw['subjectId']?.toString() ?? '',
    };
  }

  // /// 🔹 Save homework to SharedPreferences
  // Future<void> saveHomeworkToLocal() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString("homeworkList", jsonEncode(homeworkList));
  // }

  /// 🔹 Fetch subjects from API
  Future<void> fetchSubjects() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("https://api.schoolnxpro.com/api/Subject?instituteId=10085"),
      );
      if (response.statusCode == 200) {
        subjects = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
    }
    setState(() => isLoading = false);
  }

  /// 🔹 Pick file
  Future<void> pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        attachmentFile = File(result.files.single.path!);
      });
    }
  }

  final fromDateFormat = DateFormat('yyyy-MM-dd'); 
  final toDateFormat = DateFormat('yyyy-MM-dd'); 

  /// 🔹 Homework Dialog
  Future<void> addHomeworkDialog() async {
    TextEditingController titleCtrl = TextEditingController();
    TextEditingController descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Homework"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Dates
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateDialog(() => fromDate = picked);
                        }
                      },
                      child: Text(fromDate == null
                          ? "Select From Date"
                          : "From: ${fromDateFormat.format(fromDate!)}", style: TextStyle(color: Colors.black),),
                    ),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateDialog(() => toDate = picked);
                        }
                      },
                      child: Text(toDate == null
                          ? "Select To Date"
                          : "To: ${toDateFormat.format(toDate!)}", style: TextStyle(color: Colors.black),),
                    ),

                    // Subject dropdown
                    DropdownButtonFormField(
                      decoration: const InputDecoration(labelText: "Subject"),
                      value: selectedSubject,
                      items: subjects
                          .map((s) => DropdownMenuItem(
                                value: s["subjectId"].toString(),
                                child: Text(s["subjectName"]),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() => selectedSubject = val as String);
                      },
                    ),

                    // Title & Desc
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Homework Title"),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),

                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  // onPressed: () async {
                  //   final hw = {
                  //     "subjectId": selectedSubject,
                  //     "subject": subjects.firstWhere(
                  //         (s) => s["subjectId"].toString() == selectedSubject)["subjectName"],
                  //     "title": titleCtrl.text,
                  //     "description": descCtrl.text,
                  //     "fromDate": fromDate.toString().split(" ")[0],
                  //     "toDate": toDate.toString().split(" ")[0],
                  //     "attachment": attachmentFile?.path,
                  //   };

                  onPressed: () async {
                    if (titleCtrl.text.isEmpty ||
                        descCtrl.text.isEmpty ||
                        selectedSubject == null ||
                        fromDate == null ||
                        toDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }

                    final subjectName = subjects
                        .firstWhere(
                          (s) =>
                              s["subjectId"].toString() ==
                              selectedSubject,
                        )["subjectName"]
                        .toString();

                    final localHomework = {
                      "subjectId": selectedSubject,
                      "subject": subjectName,
                      "title": titleCtrl.text,
                      "description": descCtrl.text,
                      "fromDate": DateFormat('yyyy-MM-dd').format(fromDate!),
                      "toDate": DateFormat('yyyy-MM-dd').format(toDate!),
                      "attachment": attachmentFile?.path,
                      "extensions": attachmentFile != null
                          ? ".${attachmentFile!.path.split('.').last}"
                          : '',
                      "homeWorkId": "",
                    };

                    setState(() {
                      isLoading = true;
                    });

                    final isOnline = await _syncService.isOnline();
                    Map<String, dynamic>? apiResponse;
                    SyncStatus syncStatus = SyncStatus.pending;

                    if (isOnline) {
                      // Try to save to API immediately
                      final homeworkProvider =
                          Provider.of<HomeworkProvider>(context, listen: false);

                      apiResponse = await homeworkProvider.addHomework(
                        subjectId: selectedSubject!,
                        homeWorkDate: DateFormat('dd-MM-yyyy').format(fromDate!),
                        homeWorkDueOnDate:
                            DateFormat('dd-MM-yyyy').format(toDate!),
                        homeWorkName: titleCtrl.text,
                        homeWorkDescription: descCtrl.text,
                        attachmentPath: attachmentFile?.path,
                      );

                      if (apiResponse != null) {
                        syncStatus = SyncStatus.synced;
                      } else {
                        // API call failed, queue for retry
                        syncStatus = SyncStatus.failed;
                        await _syncService.addToFailedQueue(localHomework);
                      }
                    } else {
                      // Offline: add to pending queue
                      syncStatus = SyncStatus.pending;
                      await _syncService.addToPendingQueue(localHomework);
                    }

                    final enrichedHomework = {
                      ...localHomework,
                      // Add both field formats for compatibility
                      "subjectName": subjectName, // For HomeworkItem mapping
                      "homeWorkName": titleCtrl.text, // For HomeworkItem mapping
                      "homeWorkDescription": descCtrl.text, // For HomeworkItem mapping
                      "homeWorkDate": DateFormat('yyyy-MM-dd').format(fromDate!), // For HomeworkItem mapping
                      "homeWorkDueOnDate": DateFormat('yyyy-MM-dd').format(toDate!), // For HomeworkItem mapping
                      "homeWorkId":
                          apiResponse?['homeWorkId']?.toString() ?? "",
                      "attachment": apiResponse?['attachment'] ??
                          localHomework['attachment'],
                      "extensions": apiResponse?['extensions'] ??
                          localHomework['extensions'],
                      "syncStatus": syncStatus.name,
                    };

                    // Save locally with sync status
                    await _syncService.saveHomeworkLocally(
                      enrichedHomework,
                      syncStatus: syncStatus,
                    );

                    setState(() {
                      homeworkList.add(enrichedHomework);
                    });

                    final studentId = await MySharedPreferences.instance
                            .getStringValue("studentId") ??
                        '';
                    if (studentId.isNotEmpty) {
                      final parentHomeworkProvider =
                          Provider.of<HomeworkProviders>(context,
                              listen: false);
                      final homeworkItem = HomeworkItem.fromLocalMap(
                          Map<String, dynamic>.from(enrichedHomework));
                      
                      // Add to provider's local list immediately
                      await parentHomeworkProvider.addLocalHomework(
                        studentId,
                        homeworkItem,
                      );
                      
                      // If successfully synced, wait a moment for API to propagate, then refresh
                      if (syncStatus == SyncStatus.synced && apiResponse != null) {
                        await Future.delayed(const Duration(milliseconds: 500));
                      }
                      
                      // Force refresh to get latest from API + local
                      await parentHomeworkProvider.fetchHomework(
                        studentId,
                        forceRefresh: true,
                      );
                    }

                    await loadAllHomework();
                    if (mounted) {
                      setState(() {
                        isLoading = false;
                        attachmentFile = null;
                      });
                    }

                    if (!mounted) return;
                    Navigator.of(context).pop(); // close dialog only; stay on HomeworkScreen so list shows new item

                    final message = isOnline && apiResponse != null
                        ? "Homework added and synced successfully!"
                        : isOnline
                            ? "Homework saved locally. Sync failed, will retry automatically."
                            : "Homework saved locally. Will sync when online.";
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔹 Show homework details
  void showHomeworkDetails(Map<String, dynamic> hw) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(hw["title"] ?? ""),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Subject: ${hw["subject"]}"),
            Text("From: ${hw["fromDate"]}"),
            Text("To: ${hw["toDate"]}"),
            Text("Description: ${hw["description"]}"),
            if (hw["attachment"] != null)
              Text("Attachment: ${hw["attachment"].split('/').last}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  /// 🔹 UI
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
      body: _studentId != null
          ? Consumer<HomeworkProviders>(
              builder: (context, homeworkProviders, _) {
                final list = homeworkProviders.homeworkList;
                if (homeworkProviders.isLoading && list.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return const Center(child: Text("No Homework Added"));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await homeworkProviders.fetchHomework(
                      _studentId!,
                      forceRefresh: true,
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _HomeworkCardWidget(homework: list[index]);
                    },
                  ),
                );
              },
            )
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : homeworkList.isEmpty
                  ? const Center(child: Text("No Homework Added"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: homeworkList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = HomeworkItem.fromLocalMap(
                          Map<String, dynamic>.from(homeworkList[index]),
                        );
                        return _HomeworkCardWidget(homework: item);
                      },
                    ),
    );
  }
}

/// Card matching parent homework screen: purple header (subject, date, status), white body (Title, Due On, Attachment, Description).
class _HomeworkCardWidget extends StatelessWidget {
  final HomeworkItem homework;

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
          // Purple header: Subject (left), Date + Status (right)
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
                    homework.subjectName,
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
                  homework.formattedAssignedDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                _HomeworkStatusIcon(syncStatus: homework.syncStatus),
              ],
            ),
          ),
          // White body: Title, Due On, Attachment, Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Title", homework.homeWorkName),
                _infoRow("Due On", homework.formattedDueDate),
                _attachmentRow(context, homework),
                _infoRow("Description", homework.homeWorkDescription),
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
            child: Text(
              "$label :",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value.isEmpty ? "-" : value,
              maxLines: label == "Description" ? 4 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentRow(BuildContext context, HomeworkItem hw) {
    final attachment = hw.attachmentUrl ?? hw.attachmentPath;
    if (attachment == null || attachment.isEmpty) {
      return _infoRow("Attachment", "-");
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              "Attachment :",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () async {
                final uri = attachment.startsWith('http')
                    ? Uri.parse(attachment)
                    : Uri.file(attachment);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Unable to open attachment")),
                  );
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder, size: 18, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    "View Attachment",
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

class _HomeworkStatusIcon extends StatelessWidget {
  final SyncStatus syncStatus;

  const _HomeworkStatusIcon({required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    switch (syncStatus) {
      case SyncStatus.synced:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.pending:
      case SyncStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 20);
    }
  }
}
