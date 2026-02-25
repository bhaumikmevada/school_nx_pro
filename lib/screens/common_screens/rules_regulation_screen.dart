import 'package:flutter/material.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';

class RulesRegulationScreen extends StatefulWidget {
  const RulesRegulationScreen({super.key});

  @override
  State<RulesRegulationScreen> createState() => _RulesRegulationScreenState();
}

class _RulesRegulationScreenState extends State<RulesRegulationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const ParentAppbar(
        title: "Rules & Regulation",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ListView(
          children: const [
            RulesTile(
              title: 'Attendance: ',
              subTitle:
                  'Students should attend school regularly and on time. Parents are legally required to ensure their children attend school.',
            ),
            RulesTile(
              title: 'Dress code: ',
              subTitle:
                  'Students should wear the school uniform and dress appropriately for the school environment.',
            ),
            RulesTile(
              title: 'Behaviour: ',
              subTitle:
                  'Students should be courteous, and honest. They should also avoid abusive language, quarrelling, shouting, and whistling.',
            ),
            RulesTile(
              title: 'Electronics: ',
              subTitle:
                  'Students may not be allowed to bring mobile phones or other electronic devices to school.',
            ),
            RulesTile(
              title: 'Food: ',
              subTitle:
                  'Students may be required to bring healthy and nutritious food to school.',
            ),
            RulesTile(
              title: 'Chewing gum: ',
              subTitle:
                  'Chewing gum may not be allowed in school, especially during class.',
            ),
            RulesTile(
              title: 'Cleanliness: ',
              subTitle:
                  'Students should keep the school premises and classrooms clean and tidy.',
            ),
            RulesTile(
              title: 'School property: ',
              subTitle: 'Students should take care of school property.',
            ),
          ]
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: e,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class RulesTile extends StatelessWidget {
  const RulesTile({
    super.key,
    required this.title,
    required this.subTitle,
  });

  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            height: 10,
            width: 10,
            decoration: const BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: boldBlack.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextSpan(
                  text: subTitle,
                  style: normalBlack.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
