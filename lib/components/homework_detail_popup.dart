import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/common_popup.dart';
import 'package:school_nx_pro/theme/font_theme.dart';

class HomeworkDetailPopup {
  final BuildContext context;
  final String? homeworkDate;
  final String? homeworkDueDate;
  final String? subject;
  final String? homeworkTitle;
  final String? fullAllotmentName;
  final String? attachment;

  HomeworkDetailPopup({
    required this.context,
    this.homeworkDate,
    this.homeworkDueDate,
    this.subject,
    this.homeworkTitle,
    this.fullAllotmentName,
    this.attachment,
  });

  void show() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CommonPopup(
          title: 'HomeWork Detail',
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'HomeWork Date :',
                  homeworkDate ?? "N/A",
                ),
                _buildDetailRow(
                  'HomeWork Due On :',
                  homeworkDueDate ?? "N/A",
                ),
                _buildDetailRow(
                  'Subject :',
                  subject ?? "N/A",
                ),
                _buildDetailRow(
                  'HomeWork Title :',
                  homeworkTitle ?? "N/A",
                ),
                _buildDetailRow(
                  'Full Allotment Name :',
                  fullAllotmentName ?? "N/A",
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachment :',
                      style: boldBlack.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Image.network(
                        "https://picsum.photos/100",
                        height: 300,
                        width: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.wallpaper,
                            size: 100,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ]
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 15),
                      child: e,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "$label ",
            style: boldBlack.copyWith(fontSize: 15),
          ),
          TextSpan(
            text: value,
            style: normalBlack,
          ),
        ],
      ),
    );
  }
}
