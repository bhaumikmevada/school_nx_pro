import 'package:flutter/material.dart';

class CommonPopup extends StatefulWidget {
  final Widget child;
  final String title;

  const CommonPopup({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<CommonPopup> createState() => _CommonPopupState();
}

class _CommonPopupState extends State<CommonPopup> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
