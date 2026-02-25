import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'CustomText.dart';
import 'ImageUtils.dart';
import 'StringUtils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSize{

  String title;
  AppBar appBar;
  bool isBackIcon;
  VoidCallback? onBackPress;
  bool isBackListener = false;

  CustomAppBar({
    super.key,
    required this.appBar,
    required this.title,
    this.isBackIcon = true,
    this.onBackPress,
    this.isBackListener = false,
  });

  @override
  Widget build(BuildContext context) {

    return AppBar(
      backgroundColor: AppColors.whiteColor,
      elevation: 5.0,
      bottomOpacity: 2.0,
      automaticallyImplyLeading: false,
      surfaceTintColor: AppColors.whiteColor,
      titleSpacing: 0.0,
      title: _buildTitle(context, title),

    );
  }

  Widget _buildTitle(BuildContext context, String title) {

    return Row(
      children: [
        isBackIcon ? _buildBackIcon(context) : Container(margin: EdgeInsets.only(left: 20,),),


        Expanded(
          child: Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(right: 30),
            child: CustomText.TextRegular(
              title,
              fontSize: 16.0,
              color: AppColors.blackColor,
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildBackIcon(BuildContext context){

    return Container(
      margin: EdgeInsets.only(top: 5),
      child: IconButton(
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onPressed: () {

          if(isBackListener){
            onBackPress?.call();
          }else{
            Navigator.pop(context);
          }
        },
        icon: Transform.rotate(
          angle:  0,
          child: SvgPicture.asset(
            AppIcons.backArrow,
            width: 30,
            height: 30,
          ),
        ),
      ),
    );

  }

  @override
  Widget get child => throw UnimplementedError();

  @override
  Size get preferredSize => Size.fromHeight(appBar.preferredSize.height);
}
