import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.mainTitle = "",
    required this.upperTitle,
    required this.widget,
    this.onTap,
    this.isImage = false,
    this.imageUrl,
  });

  final String mainTitle;
  final String upperTitle;
  final Widget widget;
  final bool isImage;
  final VoidCallback? onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;

    if (isImage && imageUrl != null && imageUrl!.isNotEmpty) {
      try {
        // Remove any data URL prefix (if present)
        String base64String = imageUrl!.split(',').last;
        imageBytes = base64Decode(base64String);
      } catch (e) {
        debugPrint("Error decoding Base64 image: $e");
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: AppColors.blue),
        ),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 2.8,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  child: isImage && imageBytes != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(25),
                          ),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 110,
                          ),
                        )
                      : Center(
                          child: Text(
                            isImage ? "No Image" : mainTitle,
                            textAlign: TextAlign.center,
                            style: normalWhite.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            upperTitle,
                            textAlign: TextAlign.center,
                            style: normalBlack.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Divider(color: AppColors.blue),
                        widget,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
