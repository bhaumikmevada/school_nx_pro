import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/utils.dart';

// Import required models and service          // Your EventModel
import 'package:school_nx_pro/models/event_list_model.dart';

import '../../utils/api_urls.dart';
import '../../utils/http_client_manager.dart';
import '../../utils/my_sharepreferences.dart';
import '../employee/screens/employee_event_screen.dart';     // For eventListModelFromJson

//khushi


class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.userType});

  final UserType userType;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Future<List<EventModel>> futureEvents;
  bool loading = true;
  String _selectedFilterYear = "";
  String _selectedFilterMonth = "";
  @override
  void initState() {
    super.initState();
    // loadEventData();
    final DateTime _currentDate = DateTime.now();
    _selectedFilterYear = DateFormat('yyyy').format(_currentDate);
    _selectedFilterMonth = DateTime.now().month.toString();
    debugPrint("selectedFilterDate : $_selectedFilterMonth,$_selectedFilterYear");
    futureEvents = fetchEventsByMonth(
      year: int.parse(_selectedFilterYear),
      month: int.parse(_selectedFilterMonth),
    );

  }

  static Future<List<EventModel>> fetchEventsByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final client = HttpClientManager.instance.getClient();

      String? instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
      instituteId ??= "10085";

      final url = Uri.parse(
        "${ApiUrls.baseUrl}Event/GetEventCalendar?instituteId=$instituteId&year=$year&month=$month",
      );

      debugPrint("📡 Calling GetEventCalendar: $url");

      final response = await client.get(url);

      if (response.statusCode == 200) {
        final eventListModel = eventListModelFromJson(response.body);

        if (!eventListModel.success) {
          print("API returned success: false");
          return [];
        }

        // Convert nested structure (Day → Events) into flat EventModel list
        List<EventModel> eventModels = [];

        for (var day in eventListModel.days) {
          for (var event in day.events) {
            eventModels.add(
              EventModel(
                eventId: event.eventId, // API doesn't return eventId, so we use 0 or generate one
                eventName: event.eventName,
                eventDate: day.date,
                courseId: event.courseId,
                courseName: event.courseName,
                images: event.images,
              ),
            );
          }
        }

        // Sort by date (newest first)
        eventModels.sort((a, b) => b.eventDate.compareTo(a.eventDate));

        debugPrint("✅ Loaded ${eventModels.length} events for $month/$year");
        return eventModels;
      } else {
        print("❌ API Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ fetchEventsByMonth Error: $e");
      return [];
    }
  }

  void loadEventData() async {
    setState(() {
      loading = true;
    });

    // try {
    //   // Using the same fetchEventsByMonth method from Employee code
    //   events = await fetchEventsByMonth(
    //     year: DateTime.now().year,
    //     month: DateTime.now().month,
    //   );
    // } catch (e) {
    //   debugPrint("❌ Error fetching event data: $e");
    //   events = [];
    // }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: const ParentAppbar(
        title: "Events",
      ),
      body: FutureBuilder<List<EventModel>>(
        future: futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Events Found"));
          } else {
            final events = snapshot.data!;
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Container(
                  margin: const EdgeInsets.all(5),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.colorcfcfcf, width: 1),
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.colorcfcfcf,
                        blurRadius: 2.0,
                        offset: const Offset(1.0, 0.0),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          // Date Badge (Top Right)
                          Container(
                            width: 100,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(9),
                              ),
                              color: AppColors.blue,
                            ),
                            child: CustomText.TextMedium(
                              Utils.convertDateFormat(
                                inputDate: event.eventDate.toString(),
                                inputFormat: 'yyyy-MM-dd',
                                outputFormat: 'dd-MM-yyyy',
                              ),
                              fontSize: 13.0,
                              color: AppColors.whiteColor,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Main Content
                          Container(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Event Image
                                event.images.isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    event.images[0],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported),
                                      );
                                    },
                                  ),
                                )
                                    : Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.event,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Event Name
                                CustomText.TextSemiBold(
                                  event.eventName.toString(),
                                  color: AppColors.blackColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}