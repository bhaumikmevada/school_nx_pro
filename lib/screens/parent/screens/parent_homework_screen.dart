import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_nx_pro/provider/parent_homework_provider.dart';
import 'package:school_nx_pro/services/homework_sync_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_theme.dart';
import '../../../utils/api_urls.dart';
import '../../../utils/enum.dart';
import '../../../utils/my_sharepreferences.dart';
import '../../../utils/utils.dart';
import '../parent_components/parent_appbar.dart';

class ParentHomeworkScreen extends StatefulWidget {
  final UserType userType;
  final String studentId;

  ParentHomeworkScreen({super.key,required this.userType,required this.studentId});

  @override
  State<ParentHomeworkScreen> createState() => _ParentHomeworkScreenState();
}

class _ParentHomeworkScreenState extends State<ParentHomeworkScreen> {

  List<dynamic> homeworkList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchHomeworkList();
  }

  Future<void> fetchHomeworkList() async {
    setState(() => isLoading = true);
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

    try {
      final response = await http.get(
        Uri.parse(
          "${ApiUrls.baseUrl}HomeworkUpload1/list?instituteId=$instituteId",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        title: Text(
          "Home Work",
          style: boldBlack.copyWith(fontSize: 18),
        ),
        actions: [
        ],
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
