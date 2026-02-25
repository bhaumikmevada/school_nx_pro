import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_dropdown.dart';
import 'package:school_nx_pro/components/app_textfield.dart';
import 'package:school_nx_pro/components/common_popup.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/subject_model.dart';
import 'package:school_nx_pro/provider/homework_provider.dart';

class AddHomeworkPopup {
  final BuildContext context;

  AddHomeworkPopup({required this.context});

  void show() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Builder(
          builder: (BuildContext newContext) {
            return _AddHomeworkDialogContent();
          },
        );
      },
    );
  }
}

class _AddHomeworkDialogContent extends StatefulWidget {
  @override
  _AddHomeworkDialogContentState createState() =>
      _AddHomeworkDialogContentState();
}

class _AddHomeworkDialogContentState extends State<_AddHomeworkDialogContent> {
  DateTime? selectedDate = DateTime.now();
  DateTime? selectedDueDate = DateTime.now();
  final TextEditingController homeworkDate = TextEditingController();
  final TextEditingController homeworkDueOnController = TextEditingController();
  final TextEditingController homeWorkTitleController = TextEditingController();
  final TextEditingController fullAllotmentNameController =
      TextEditingController();
  final TextEditingController chooseFile = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? subject = 'English';
  String? fullAllotmentName = 'Demo Full Allotment Name';

  late HomeworkProvider provider;

  int? selectedSubjectId;
  SubjectModel? selectedSubjectObject;

  @override
  void initState() {
    super.initState();
    homeworkDate.text = DateFormat('dd-MM-yyyy').format(selectedDate!);
    homeworkDueOnController.text =
        DateFormat('dd-MM-yyyy').format(selectedDueDate!);

    provider = Provider.of<HomeworkProvider>(context, listen: false);
    provider.getSubject();
    setState(() {});
  }

  @override
  void dispose() {
    homeworkDate.dispose();
    homeworkDueOnController.dispose();
    homeWorkTitleController.dispose();
    fullAllotmentNameController.dispose();
    chooseFile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonPopup(
      title: 'Homework Entry',
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                labelText: "Homework Date",
                isSuffixIcon: true,
                controller: homeworkDate,
                suffixIcon: IconButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                        homeworkDate.text =
                            DateFormat('dd-MM-yyyy').format(selectedDate!);
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.calendar_month,
                    size: 30,
                  ),
                ),
              ),
              AppTextField(
                labelText: "HomeWord Due On",
                isSuffixIcon: true,
                controller: homeworkDueOnController,
                suffixIcon: IconButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        selectedDueDate = pickedDate;
                        homeworkDueOnController.text =
                            DateFormat('dd-MM-yyyy').format(selectedDueDate!);
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.calendar_month,
                    size: 30,
                  ),
                ),
              ),
              Consumer<HomeworkProvider>(
                builder: (context, provider, child) {
                  return AppDropDown(
                    labelText: "Select Subject",
                    value: selectedSubjectObject != null
                        ? '${selectedSubjectObject!.subjectName} (${selectedSubjectObject!.subjectId})'
                        : null,
                    items: provider.getSubjectList
                        .map((subject) =>
                            '${subject.subjectName} (${subject.subjectId})')
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedSubjectObject =
                              provider.getSubjectList.firstWhere(
                            (subject) =>
                                '${subject.subjectName} (${subject.subjectId})' ==
                                newValue,
                            orElse: () => SubjectModel(
                                subjectId: -1, subjectName: 'Unknown'),
                          );
                          selectedSubjectId = selectedSubjectObject?.subjectId;
                        });
                      }
                    },
                  );
                },
              ),
              AppTextField(
                labelText: "HomeWork Title",
                controller: homeWorkTitleController,
              ),
              AppTextField(
                labelText: "HomeWork Description",
                controller: fullAllotmentNameController,
              ),
              // AppDropDown(
              //   labelText: "Full Allotment Name",
              //   value: fullAllotmentName,
              //   items: const [
              //     "Demo Full Allotment Name",
              //   ],
              //   onChanged: (value) {
              //     setState(() {
              //       fullAllotmentName = value;
              //     });
              //   },
              // ),
              // AppTextField(
              //   labelText: "Choose File",
              //   isSuffixIcon: true,
              //   controller: chooseFile,
              //   suffixIcon: IconButton(
              //     onPressed: () async {},
              //     icon: const Icon(
              //       Icons.cloud_upload,
              //       size: 30,
              //     ),
              //   ),
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppButton(
                      buttonText: "Cancel",
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: Colors.black45,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: AppButton(
                      buttonText: "Save",
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () {
                        if (selectedSubjectObject == null) {
                          scaffoldMessage(message: "Please select a subject");
                        }
                        if (homeworkDate.text.isEmpty) {
                          scaffoldMessage(
                              message: "Please select a Homework Date");
                        }
                        if (homeworkDueOnController.text.isEmpty) {
                          scaffoldMessage(
                              message: "Please select a Homework due Date");
                        }
                        if (homeWorkTitleController.text.isEmpty) {
                          scaffoldMessage(
                              message: "Please Enter HomeWork Title");
                        }
                        if (fullAllotmentNameController.text.isEmpty) {
                          scaffoldMessage(
                              message: "Please Enter HomeWork Description");
                        } else {
                          provider
                              .addHomework(
                            subjectId: selectedSubjectId.toString(),
                            homeWorkDate: homeworkDate.text.toString(),
                            homeWorkDueOnDate:
                                homeworkDueOnController.text.toString(),
                            homeWorkName:
                                homeWorkTitleController.text.toString(),
                            homeWorkDescription:
                                fullAllotmentNameController.text.toString(),
                          )
                              .then((success) {
                            if (success == true) {
                              provider.getHomework(); // 🔥 Refresh list from API
                              Navigator.pop(context);
                            }
                          });
                        }
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
      ),
    );
  }
}
