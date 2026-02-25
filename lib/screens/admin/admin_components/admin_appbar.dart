import 'package:flutter/material.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';

class AdminAppbar extends StatefulWidget implements PreferredSizeWidget {
  const AdminAppbar({
    super.key,
    this.isDash = false,
    this.title = "",
  });
  final bool isDash;
  final String title;

  @override
  State<AdminAppbar> createState() => _AdminAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AdminAppbarState extends State<AdminAppbar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgColor,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Text(
        widget.isDash ? "" : widget.title,
        style: boldBlack.copyWith(fontSize: 18),
      ),
      actions: [
        widget.isDash
            ? IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(
                  Icons.menu,
                  size: 30,
                ),
              )
            : IconButton(
                onPressed: () {
                  Navigator.pop(context);
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
                    size: 30,
                  ),
                ),
              )
      ],
    );
  }
}
