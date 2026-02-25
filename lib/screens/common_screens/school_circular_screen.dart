import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/app_card.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_gallery_screen.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/enum.dart';
//khushi
class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.userType});

  final UserType userType;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List<EventGallery> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEventData();
  }

  void loadEventData() async {
    try {
      events = await fetchGalleryData();
    } catch (e) {
      debugPrint("Error fetching event data: $e");
    }

    setState(() {
      loading = false;
    });
  }
  
  // late SchoolCircularProvider provider;

  // bool loading = true, loader = false;

  // @override
  // void initState() {
  //   super.initState();
  //   setState(() {
  //     loader = true;
  //   });

  //   provider = Provider.of<SchoolCircularProvider>(context, listen: false);

  //   provider.getSchoolCircular().then((value) {
  //     loader = false;
  //     loading = false;
  //     setState(() {});
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const ParentAppbar(
        title: "Events",
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : events.isEmpty
            ? const Center(child: Text("No data available"))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return AppCard(
                      mainTitle: event.eventDate,
                      upperTitle: event.eventName,
                      widget: Text(
                        event.eventDate,
                        style: normalBlack,
                      ),
                    );
                  },
                ),
              ),
      // body: loading
      //     ? const Center(child: CircularProgressIndicator())
      //     : Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 15),
      //         child:
      //             Selector<SchoolCircularProvider, List<SchoolCircularModel>>(
      //           selector: (p0, p1) => p1.getSchoolCircularList,
      //           builder: (context, circularList, child) {
      //             return circularList.isEmpty
      //                 ? const Center(
      //                     child: Text("No Data Awailable"),
      //                   )
      //                 : ListView.builder(
      //                     shrinkWrap: true,
      //                     itemCount: circularList.length,
      //                     itemBuilder: (context, index) {
      //                       final circular = circularList[index];

      //                       final formattedDate =
      //                           '${circular.eventDate.day}-${circular.eventDate.month}-${circular.eventDate.year}';

      //                       final dayOfWeek =
      //                           DateFormat('EEEE').format(circular.eventDate);

      //                       final String base64String = circular.imageBase64;

      //                       return AppCard(
      //                         onTap: () {
      //                           CircularDetailPopup(
      //                             attachmentUrl: base64String,
      //                             context: context,
      //                             eventName: circular.eventName,
      //                             date: formattedDate,
      //                             day: dayOfWeek,
      //                           ).show();
      //                         },
      //                         isImage: true,
      //                         upperTitle: circular.eventName,
      //                         imageUrl: base64String,
      //                         widget: Row(
      //                           mainAxisAlignment:
      //                               MainAxisAlignment.spaceEvenly,
      //                           children: [
      //                             Text(formattedDate, style: normalBlack),
      //                             Text("-", style: normalBlack),
      //                             Text(dayOfWeek, style: normalBlack),
      //                           ],
      //                         ),
      //                       );
      //                     },
      //                   );
      //           },
      //         ),
      //       ),
    );
  }
}
