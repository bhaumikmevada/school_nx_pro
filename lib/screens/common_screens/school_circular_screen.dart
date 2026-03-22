import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/app_card.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_gallery_screen.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/utils.dart';
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
      backgroundColor: AppColors.whiteColor,
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
                    // return AppCard(
                    //   mainTitle: event.eventDate,
                    //   upperTitle: event.eventName,
                    //   widget: Text(
                    //     event.eventDate,
                    //     style: normalBlack,
                    //   ),
                    // );

                    return Container(
                      margin: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.colorcfcfcf,width: 1),
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: AppColors.colorcfcfcf,blurRadius: 2.0,offset: Offset(1.0, 0.0))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [

                          Stack(
                            alignment: Alignment.topRight,
                            children: [

                              Container(
                                width: 100,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(9)
                                    ),
                                    color: AppColors.blue
                                ),
                                child: CustomText.TextMedium(Utils.convertDateFormat(inputDate: event.eventDate, inputFormat: 'yyyy-MM-dd', outputFormat: 'dd-MM-yyyy'),fontSize: 13.0,color: AppColors.whiteColor,textAlign: TextAlign.center),
                              ),

                              Container(
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  children: [

                                    event.images.isNotEmpty ?
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        event.images[0],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ) : Container(width: 80,height: 80,),

                                    const SizedBox(width: 10,),

                                    CustomText.TextSemiBold(event.eventName,color: AppColors.blackColor),


                                  ],
                                ),
                              )

                            ],
                          )
                        ],
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
