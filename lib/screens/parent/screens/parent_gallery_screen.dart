import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/http_client_manager.dart';

class EventGallery {
  final int eventId;
  final String eventName;
  final String eventDate;
  final List<String> images;

  EventGallery({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.images,
  });

  factory EventGallery.fromJson(Map<String, dynamic> json) {
    return EventGallery(
      eventId: json['eventId'],
      eventName: json['eventName'],
      eventDate: json['eventDate'].substring(0, 10),
      images: List<String>.from(json['images']),
    );
  }
}

Future<List<EventGallery>> fetchGalleryData() async {
  const url = 'https://api.schoolnxpro.com/api/EventWithImages?instituteId=10085';
  final client = HttpClientManager.instance.getClient();
  final response = await client.get(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final body = json.decode(response.body);
    List<EventGallery> events = [];

    for (var event in body['data']) {
      events.add(EventGallery.fromJson(event));
    }

    return events;
  } else {
    throw Exception('Failed to load gallery data');
  }
}

class ParentGalleryScreen extends StatefulWidget {
  const ParentGalleryScreen({super.key});

  @override
  State<ParentGalleryScreen> createState() => _ParentGalleryScreenState();

  static void showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Image.network(
                  imageUrl,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.wallpaper,
                      color: AppColors.bgColor,
                      size: 100,
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                child: AppButton(
                  buttonText: "Download",
                  onTap: () async {
                    // await downloadImage(context, imageUrl);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // static Future<void> downloadImage(BuildContext context, String imageUrl) async {
  //   try {
  //     var status = await Permission.storage.status;
  //     if (!status.isGranted) {
  //       await Permission.storage.request();
  //     }
  //
  //     var imageId = await ImageDownloader.downloadImage(imageUrl);
  //
  //     if (imageId == null) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Image downloaded successfully")),
  //     );
  //   } catch (error) {
  //     debugPrint("Error downloading image: $error");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Failed to download image")),
  //     );
  //   }
  // }
}

class _ParentGalleryScreenState extends State<ParentGalleryScreen> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    double cardHeight = MediaQuery.of(context).size.height;
    int crossAxisCount;
    double childAspectRatio;

    if (screenSize.width > 800 || screenSize.width >= 800) {
      crossAxisCount = 5;
      childAspectRatio = (cardHeight / crossAxisCount) / 100;
    } else {
      crossAxisCount = 3;
      childAspectRatio = (cardHeight / crossAxisCount) / 500;
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const ParentAppbar(
        title: "Photo Gallery",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: FutureBuilder<List<EventGallery>>(
        future: fetchGalleryData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No gallery data available"));
          }

          final events = snapshot.data!;
          final allImages = events
              .expand((event) => event.images.map((image) => {
                    "url": image,
                    "name": event.eventName,
                    "date": event.eventDate,
                  }))
              .toList();

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: allImages.length,
            itemBuilder: (context, index) {
              final img = allImages[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.maxFinite,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              ParentGalleryScreen.showImagePopup(context, img['url']!);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                img['url']!,
                                height: 120,
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.wallpaper,
                                      color: AppColors.bgColor,
                                      size: 50,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      img['name']!,
                      textAlign: TextAlign.center,
                      style: normalBlack.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 5),
                    Text(img['date']!),
                  ],
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
