import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_nx_pro/provider/parent_homework_provider.dart';
import 'package:school_nx_pro/services/homework_sync_service.dart';
import '../../../utils/enum.dart';
import '../parent_components/parent_appbar.dart';

class ParentHomeworkScreen extends StatelessWidget {
  final UserType userType;
  final String studentId;

  const ParentHomeworkScreen({super.key, required this.userType, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeworkProviders>(context, listen: false);

    // Fetch homework when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchHomework(studentId, forceRefresh: true);
    });

    return Scaffold(
      appBar: const ParentAppbar(title: "Home Work"),
      body: Consumer<HomeworkProviders>(
        builder: (context, homeworkProviders, child) {
          final homeworkList = homeworkProviders.homeworkList;

          if (homeworkProviders.isLoading && homeworkList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (homeworkList.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  homeworkProviders.fetchHomework(studentId, forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text("No homework found")),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                homeworkProviders.fetchHomework(studentId, forceRefresh: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final hw = homeworkList[index];
                return _HomeworkCard(homework: hw, studentId: studentId);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: homeworkList.length,
            ),
          );
        },
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkItem homework;
  final String studentId;

  const _HomeworkCard({required this.homework, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final headerColor = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                _SyncStatusIcon(syncStatus: homework.syncStatus),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Title", homework.homeWorkName),
                _infoRow("Due On", homework.formattedDueDate),
                _attachmentRow(context, homework),
                _infoRow("Description", homework.homeWorkDescription),
                // if (homework.syncStatus != SyncStatus.synced)
                //   _syncStatusRow(context, homework),
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
              child: const Text(
                "📁 View Attachment",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncStatusRow(BuildContext context, HomeworkItem homework) {
    final syncService = HomeworkSyncService();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _SyncStatusIcon(syncStatus: homework.syncStatus),
                const SizedBox(width: 8),
                Text(
                  _getSyncStatusText(homework.syncStatus),
                  style: TextStyle(
                    color: _getSyncStatusColor(homework.syncStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (homework.syncStatus == SyncStatus.failed ||
              homework.syncStatus == SyncStatus.pending)
            TextButton.icon(
              onPressed: () async {
                if (homework.tempLocalId != null) {
                  final success = await syncService.retryFailedSync(
                    homework.tempLocalId!,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? "Sync retry successful!"
                            : "Sync retry failed. Please check your connection."),
                      ),
                    );
                    // Refresh the list
                    final provider =
                        Provider.of<HomeworkProviders>(context, listen: false);
                    await provider.fetchHomework(studentId, forceRefresh: true);
                  }
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Retry"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return "Synced";
      case SyncStatus.syncing:
        return "Syncing...";
      case SyncStatus.pending:
        return "Pending sync";
      case SyncStatus.failed:
        return "Sync failed";
    }
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.failed:
        return Colors.red;
    }
  }
}

class _SyncStatusIcon extends StatelessWidget {
  final SyncStatus syncStatus;

  const _SyncStatusIcon({required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    switch (syncStatus) {
      case SyncStatus.synced:
        return const Icon(Icons.check_circle, color: Colors.green, size: 18);
      case SyncStatus.syncing:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.pending:
        return const Icon(Icons.schedule, color: Colors.orange, size: 18);
      case SyncStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 18);
    }
  }
}

// class ParentHomeworkScreen extends StatefulWidget {
//   final UserType userType;
//   final String studentId;
//
//   const ParentHomeworkScreen({super.key, required this.userType, required this.studentId});
//
//   @override
//   State<ParentHomeworkScreen> createState() => _ParentHomeworkScreenState();
// }
// class _ParentHomeworkScreenState extends State<ParentHomeworkScreen> {
//   Map<String, dynamic>? homeworkData;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchHomework();
//   }
//
//   Future<void> fetchHomework() async {
//     final uri = Uri.parse(
//       "https://api.schoolnxpro.com/api/Homework/Id?admissionId=${widget.studentId}&instituteId=10085",
//     );
//
//     try {
//       final response = await http.get(uri);
//       if (response.statusCode == 200) {
//         final jsonData = json.decode(response.body);
//         setState(() {
//           homeworkData = jsonData['data'];
//           isLoading = false;
//         });
//       } else {
//         throw Exception("Failed to load homework");
//       }
//     } catch (e) {
//       print("Error: $e");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   String formatDate(String dateStr) {
//     final date = DateTime.parse(dateStr);
//     return DateFormat('dd/MM/yyyy').format(date);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     print("Parent Homework Student ID :- ${widget.studentId}");
//     final hw = homeworkData?['homework'];
//
//     return Scaffold(
//       appBar: const ParentAppbar(title: "Home Work"),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : hw == null
//           ? const Center(child: Text("No homework found"))
//           : Container(
//             height: 250,
//         margin: const EdgeInsets.all(12),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8),
//           color: Colors.grey.shade100,
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 4,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with subject and due date
//             Container(
//               padding: const EdgeInsets.symmetric(
//                   vertical: 8, horizontal: 12),
//               color: Colors.lightGreen,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     homeworkData!['subjectName'] ?? '',
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
//                   ),
//                   Text(
//                     formatDate(hw['homeWorkDate']),
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//
//             // Title
//             _rowItem("Title", hw['homeWorkName']),
//             _rowItem("Due On", formatDate(hw['homeWorkDueOnDate'])),
//
//             // Attachment (can open a dummy PDF file)
//             _rowItemPDF(
//               "Attachment",
//               "📁 Attachment_${hw['homeWorkId']}${hw['extensions']}",
//             ),
//
//             _rowItem("Description", hw['homeWorkDescription']),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _rowItem(String title, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         children: [
//           Expanded(flex: 2, child: Text("$title :", style: const TextStyle(fontWeight: FontWeight.w600))),
//           Expanded(flex: 4, child: Text(value ?? "-")),
//         ],
//       ),
//     );
//   }
//
//   _rowItemPDF(String title, String? value) {
//     if (title == "Attachment") {
//       final pdfUrl = "https://schoolnx.com/SchoolWebsiteImages/Institute10085/HomeWork/Attachment_40113.pdf";
//
//       return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 4.0),
//         child: Row(
//           children: [
//             const Expanded(
//               flex: 2,
//               child: Text("Attachment :",
//                   style: TextStyle(fontWeight: FontWeight.w600)),
//             ),
//             Expanded(
//               flex: 4,
//               child: InkWell(
//                 onTap: () async {
//                   final uri = Uri.parse(pdfUrl);
//                   if (await canLaunchUrl(uri)) {
//                     await launchUrl(uri, mode: LaunchMode.externalApplication);
//                   } else {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("PDF not open")),
//                     );
//                   }
//                 },
//                 child: Text(
//                   value ?? "Attachment",
//                   style: const TextStyle(
//                     color: Colors.blue,
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//   }
// }
