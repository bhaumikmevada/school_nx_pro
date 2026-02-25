import 'dart:io';

import 'package:flutter/material.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_event_screen.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';

class EmployeeGalleryScreen extends StatefulWidget {
  const EmployeeGalleryScreen({super.key});

  @override
  State<EmployeeGalleryScreen> createState() => _EmployeeGalleryScreenState();
}

class _EmployeeGalleryScreenState extends State<EmployeeGalleryScreen> {
  late Future<List<EventModel>> futureEvents;

  @override
  void initState() {
    super.initState();
    futureEvents = EventService.fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ParentAppbar(title: "Gallery"),
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
            // all images collect kariye ek list ma
            final events = snapshot.data!;
            final allImages = events.expand((e) => e.images).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // ek row ma 3 images
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(allImages[index]),
                );
              },
            );
          }
        },
      ),
    );
  }

  // Helper function
  Widget _buildImage(String path) {
    if (path.startsWith("http")) {
      // Network image
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else {
      // Local file image
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    }
  }
}


// import 'package:flutter/material.dart';
// import 'package:schoolproject/components/app_button.dart';
// import 'package:schoolproject/screens/parent/parent_components/parent_appbar.dart';
// import 'package:schoolproject/theme/app_colors.dart';
// import 'package:schoolproject/theme/font_theme.dart';

// class EmployeeGalleryScreen extends StatefulWidget {
//   const EmployeeGalleryScreen({super.key});

//   @override
//   State<EmployeeGalleryScreen> createState() => _EmployeeGalleryScreenState();

//   static void showImagePopup(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   IconButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     icon: const Icon(
//                       Icons.close,
//                       color: Colors.black54,
//                       size: 30,
//                     ),
//                   ),
//                 ],
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 50),
//                 child: Image.network(
//                   "https://picsum.photos/100",
//                   height: 300,
//                   width: 300,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return const Icon(
//                       Icons.wallpaper,
//                       color: AppColors.bgColor,
//                       size: 100,
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
//                 child: AppButton(
//                   buttonText: "Download",
//                   onTap: () {},
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _EmployeeGalleryScreenState extends State<EmployeeGalleryScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     double cardHeight = MediaQuery.of(context).size.height;
//     int crossAxisCount;
//     double childAspectRatio;

//     if (screenSize.width > 800 || screenSize.width >= 800) {
//       crossAxisCount = 5;
//       childAspectRatio = (cardHeight / crossAxisCount) / 100;
//     } else {
//       crossAxisCount = 3;
//       childAspectRatio = (cardHeight / crossAxisCount) / 500;
//     }

//     return Scaffold(
//       backgroundColor: AppColors.bgColor,
//       appBar: const ParentAppbar(
//         title: "Photo Gallery",
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 15),
//         child: GridView.builder(
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: crossAxisCount,
//             crossAxisSpacing: 2,
//             mainAxisSpacing: 2,
//             childAspectRatio: childAspectRatio,
//           ),
//           itemCount: 10,
//           itemBuilder: (context, index) {
//             return Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Stack(
//                     children: [
//                       Container(
//                         width: double.maxFinite,
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.all(
//                             Radius.circular(10),
//                           ),
//                         ),
//                         child: GestureDetector(
//                           onTap: () {
//                             EmployeeGalleryScreen.showImagePopup(context);
//                           },
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(20),
//                             child: Image.network(
//                               "https://picsum.photos/100",
//                               height: 120,
//                               width: 100,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) {
//                                 return const Padding(
//                                   padding: EdgeInsets.all(10),
//                                   child: Icon(
//                                     Icons.wallpaper,
//                                     color: AppColors.bgColor,
//                                     size: 50,
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                       Container(
//                         height: 25,
//                         width: 25,
//                         decoration: BoxDecoration(
//                           color: Colors.black.withValues(alpha: 0.7),
//                           borderRadius: const BorderRadius.all(
//                             Radius.circular(5),
//                           ),
//                         ),
//                         child: const Center(
//                           child: Icon(
//                             Icons.download,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       )
//                     ],
//                   ),
//                   Text(
//                     "School Camp",
//                     textAlign: TextAlign.center,
//                     style: normalBlack.copyWith(fontWeight: FontWeight.w600),
//                     maxLines: 2,
//                   ),
//                   const SizedBox(height: 5),
//                   const Text("01-05-2023"),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
