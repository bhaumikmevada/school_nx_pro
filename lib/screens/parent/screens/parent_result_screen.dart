import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../components/app_button.dart';
import '../parent_components/parent_appbar.dart';
import '../../../utils/my_sharepreferences.dart';

class ParentResultScreen extends StatefulWidget {
  const ParentResultScreen({super.key});

  @override
  State<ParentResultScreen> createState() => _ParentResultScreenState();
}

class _ParentResultScreenState extends State<ParentResultScreen> {
  String? selectedTerm;
  String? selectedExam;

  String? selectedTermId;
  String? selectedExamId;

  List<Map<String, String>> termList = [];
  List<Map<String, String>> examList = [];

  List<dynamic> marksData = [];

  @override
  void initState() {
    super.initState();
    fetchTermList();
    fetchExamList();
  }

  // Helper method to get instituteId from SharedPreferences or children data
  Future<String?> _getInstituteId() async {
    // First try to get from SharedPreferences
    String? instituteId = await MySharedPreferences.instance.getStringValue('instituteId') ?? "10085";
    debugPrint("result _getInstituteId : ${instituteId}");

    // If not found, try to get from children data
    if (instituteId == null || instituteId.isEmpty) {
      String? childrenListJson = await MySharedPreferences.instance.getStringValue('childrenList');
      if (childrenListJson != null) {
        try {
          List<dynamic> childrenList = json.decode(childrenListJson);
          String? studentId = await MySharedPreferences.instance.getStringValue('studentId');
          
          if (studentId != null && childrenList.isNotEmpty) {
            for (var child in childrenList) {
              if (child['studentId']?.toString() == studentId) {
                instituteId = child['instituteId']?.toString();
                if (instituteId != null && instituteId.isNotEmpty) {
                  // Save it for future use
                  await MySharedPreferences.instance.setStringValue('instituteId', instituteId);
                  break;
                }
              }
            }
          }
          
          // If still not found, use first child's instituteId
          if ((instituteId == null || instituteId.isEmpty) && childrenList.isNotEmpty) {
            instituteId = childrenList.first['instituteId']?.toString();
            if (instituteId != null && instituteId.isNotEmpty) {
              await MySharedPreferences.instance.setStringValue('instituteId', instituteId);
            }
          }
        } catch (e) {
          print("Error parsing children list: $e");
        }
      }
    }
    
    return instituteId;
  }

  Future<void> fetchTermList() async {
    String? instituteId = await _getInstituteId();
    debugPrint("fetchTermList instituteId : $instituteId");

    if (instituteId == null || instituteId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Institute ID not found. Please login again."),
        ));
      }
      return;
    }

    final url = Uri.parse("https://api.schoolnxpro.com/api/TermName?institudeId=$instituteId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          termList = data.map((item) => {
            'id': item['termId'].toString(),
            'name': item['termName'].toString()
          }).toList();
        });
      }
    } catch (e) {
      print("Error fetching terms: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error fetching terms: $e"),
        ));
      }
    }
  }

  Future<void> fetchExamList() async {
    String? instituteId = await _getInstituteId();
    
    if (instituteId == null || instituteId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Institute ID not found. Please login again."),
        ));
      }
      return;
    }

    final url = Uri.parse("https://api.schoolnxpro.com/api/ExamName?instituteId=$instituteId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          examList = data.map((item) => {
            'id': item['examId'].toString(),
            'name': item['examName'].toString()
          }).toList();
        });
      }
    } catch (e) {
      print("Error fetching exams: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error fetching exams: $e"),
        ));
      }
    }
  }

  Future<void> fetchMarks() async {
    if (selectedTermId == null || selectedExamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select both Term and Exam"),
      ));
      return;
    }

    // Get studentId and instituteId from SharedPreferences
    String? studentId = await MySharedPreferences.instance.getStringValue('studentId');
    String? instituteId = await _getInstituteId();

    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Student ID not found. Please select a student."),
      ));
      return;
    }

    if (instituteId == null || instituteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Institute ID not found. Please login again."),
      ));
      return;
    }

    final url = Uri.parse(
        "https://api.schoolnxpro.com/api/MarkSheet/marks/$studentId?instituteId=$instituteId&termId=$selectedTermId&examId=$selectedExamId");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          final List<dynamic> subjects = jsonData['data']['subjects'];
          setState(() {
            marksData = subjects;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("No data found"),
            ));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${response.statusCode}"),
          ));
        }
      }
    } catch (e) {
      print("Error fetching marks: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error fetching marks: $e"),
        ));
      }
    }
  }

  Widget buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?, String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text("Select", style: TextStyle(color: Colors.black)),
              isExpanded: true,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item['name'],
                  child: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (newValue) {
                final selected = items.firstWhere((item) => item['name'] == newValue);
                onChanged(newValue, selected['id']);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTable() {
    if (marksData.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          "$selectedExam MARKS",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
              dataRowColor: MaterialStateProperty.all(Colors.white),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Max. Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Marks Obt.', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Grade Obt.', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: marksData.map((subject) {
                return DataRow(cells: [
                  DataCell(Text(subject['subjectName'] ?? '')),
                  DataCell(Text(subject['maximumMarks'].toString())),
                  DataCell(Text(subject['marksObtained'].toString())),
                  DataCell(Text(subject['gradeObtained'] ?? '')),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ParentAppbar(title: "Marks"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildDropdown(
                label: "Term",
                value: selectedTerm,
                items: termList,
                onChanged: (val, id) {
                  setState(() {
                    selectedTerm = val;
                    selectedTermId = id;
                  });
                },
              ),
              const SizedBox(height: 16),
              buildDropdown(
                label: "Exam",
                value: selectedExam,
                items: examList,
                onChanged: (val, id) {
                  setState(() {
                    selectedExam = val;
                    selectedExamId = id;
                  });
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                buttonText: "Show",
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: fetchMarks,
              ),
              const SizedBox(height: 20),
              buildTable(),
            ],
          ),
        ),
      ),
    );
  }
}


// class ParentResultScreen extends StatefulWidget {
//   const ParentResultScreen({super.key});
//
//   @override
//   State<ParentResultScreen> createState() => _ParentResultScreenState();
// }
//
// class _ParentResultScreenState extends State<ParentResultScreen> {
//   late ResultProvider provider;
//
//   bool isLoading = true;
//   bool isResultLoading = false;
//
//   int? selectedTermId;
//   TermModel? selectedTermObject;
//   int? selectedExamId;
//   ExamModel? selectedExamObject;
//
//   @override
//   void initState() {
//     super.initState();
//     provider = Provider.of<ResultProvider>(context, listen: false);
//     _loadInitialData();
//   }
//
//   Future<void> _loadInitialData() async {
//     setState(() => isLoading = true);
//     await provider.getTerm();
//     await provider.getExam();
//     setState(() => isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bgColor,
//       appBar: const ParentAppbar(title: "Result"),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(15),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     AppDropDown(
//                       labelText: "Select Term",
//                       value: selectedTermObject != null
//                           ? '${selectedTermObject!.termName} (${selectedTermObject!.termId})'
//                           : null,
//                       items: provider.termsList
//                           .map((term) => '${term.termName} (${term.termId})')
//                           .toList(),
//                       onChanged: (String? newValue) {
//                         if (newValue != null) {
//                           setState(() {
//                             selectedTermObject = provider.termsList.firstWhere(
//                               (term) =>
//                                   '${term.termName} (${term.termId})' ==
//                                   newValue,
//                               orElse: () =>
//                                   TermModel(termId: -1, termName: 'Unknown'),
//                             );
//                             selectedTermId = selectedTermObject?.termId;
//                           });
//                         }
//                       },
//                     ),
//                     const SizedBox(height: 15),
//                     AppDropDown(
//                       labelText: "Select Exam",
//                       value: selectedExamObject != null
//                           ? '${selectedExamObject!.examName} (${selectedExamObject!.examId})'
//                           : null,
//                       items: provider.examList
//                           .map((exam) => '${exam.examName} (${exam.examId})')
//                           .toList(),
//                       onChanged: (String? newValue) {
//                         if (newValue != null) {
//                           setState(() {
//                             selectedExamObject = provider.examList.firstWhere(
//                               (exam) =>
//                                   '${exam.examName} (${exam.examId})' ==
//                                   newValue,
//                               orElse: () =>
//                                   ExamModel(examId: -1, examName: 'Unknown'),
//                             );
//                             selectedExamId = selectedExamObject?.examId;
//                           });
//                         }
//                       },
//                     ),
//                     const SizedBox(height: 25),
//                     AppButton(
//                       buttonText: "Show Result",
//                       onTap: _fetchResult,
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                     ),
//                     const SizedBox(height: 25),
//                     if (isResultLoading)
//                       const Center(child: CircularProgressIndicator())
//                     else if (provider.getResultList.isNotEmpty)
//                       _buildResultTable(provider.getResultList.first)
//                     else
//                       const Center(child: Text("No Results Data Found!")),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
//
//   Future<void> _fetchResult() async {
//     if (selectedTermId != null && selectedExamId != null) {
//       setState(() => isResultLoading = true);
//       await provider.getResult(selectedTermId!, selectedExamId!);
//       setState(() => isResultLoading = false);
//     } else {
//       scaffoldMessage(message: "Please select both Term and Exam");
//     }
//   }
//
//   Widget _buildResultTable(ResultModel result) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Table(
//           columnWidths: const {
//             0: FlexColumnWidth(1),
//             1: FlexColumnWidth(1),
//             2: FlexColumnWidth(1),
//           },
//           children: [
//             TableRow(
//               children: [
//                 _buildTableCell('Subject', isHeader: true),
//                 _buildTableCell('Max Marks', isHeader: true),
//                 _buildTableCell('Marks Obtained', isHeader: true),
//               ],
//             ),
//             ...result.subjects.map((subject) => TableRow(
//                   children: [
//                     _buildTableCell(subject.subjectName),
//                     _buildTableCell(subject.maximumMarks.toString()),
//                     _buildTableCell(subject.marksObtained.toString()),
//                   ],
//                 )),
//           ],
//         ),
//         const SizedBox(height: 20),
//         // Row(
//         //   mainAxisAlignment: MainAxisAlignment.end,
//         //   children: [
//         //     Text(
//         //       'Result: Pass',
//         //       // 'Result: ${_calculateResult(result.subjects)}',
//         //       style: boldBlack.copyWith(fontSize: 18, color: Colors.green),
//         //     ),
//         //   ],
//         // ),
//       ],
//     );
//   }
//
//   Widget _buildTableCell(String text, {bool isHeader = false}) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//         style: TextStyle(
//           fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
//
//   // String _calculateResult(List<Subject> subjects) {
//   //   // bool passed = subjects
//   //   //     .every((subject) => subject.marksObtained! >= subject.passMarks);
//   //   return 'Pass';
//   // }
// }
