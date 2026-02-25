import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/common_popup.dart';
import 'package:school_nx_pro/theme/font_theme.dart';

class CircularDetailPopup {
  final BuildContext context;
  final String? eventName;
  final String? date;
  final String? day;
  final String? description;
  final String? attachmentUrl;

  CircularDetailPopup({
    required this.context,
    this.eventName,
    this.date,
    this.day,
    this.description,
    this.attachmentUrl,
  });

  void show() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CommonPopup(
          title: "Event Details",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attachment :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Center(
                child: _buildImageWidget(), // ✅ Updated Image Handling
              ),
              Center(
                child: Text(
                  eventName ?? "N/A",
                  style: boldBlack.copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildDetailRow('Date :', date ?? "N/A"),
              _buildDetailRow('Day :', day ?? "N/A"),
              _buildDetailRow(
                'Description :',
                description ?? "No description available.",
              ),
              const SizedBox(height: 15),
            ]
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 0, 15),
                    child: e,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  /// ✅ Improved Image Handling (Base64 & Network Images)
  Widget _buildImageWidget() {
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty) {
      try {
        if (_isBase64(attachmentUrl!)) {
          // ✅ Decode & Display Base64 Image
          return Image.memory(
            base64Decode(attachmentUrl!),
            height: 300,
            width: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _noImageWidget();
            },
          );
        } else if (attachmentUrl!.startsWith("http")) {
          // ✅ Display Network Image
          return Image.network(
            attachmentUrl!,
            height: 300,
            width: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _noImageWidget();
            },
          );
        }
      } catch (e) {
        return _noImageWidget();
      }
    }
    return _noImageWidget();
  }

  /// ✅ Checks if the String is a Valid Base64 Encoded Image
  bool _isBase64(String str) {
    final base64RegExp = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    if (str.length % 4 == 0 && base64RegExp.hasMatch(str)) {
      try {
        base64Decode(str);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// ✅ Placeholder for "No Image Available"
  Widget _noImageWidget() {
    return Container(
      height: 300,
      width: 300,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: const Text(
        "No Image Available",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// ✅ Helper Function to Build Detail Rows
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
