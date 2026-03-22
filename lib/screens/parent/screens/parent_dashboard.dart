import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_homework_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_old_receipts_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_result_screen.dart';
import 'package:school_nx_pro/utils/StringUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_card.dart';
import 'package:school_nx_pro/components/app_textfield.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/provider/parent_dashboard_provider.dart';
import 'package:school_nx_pro/provider/parent_homework_provider.dart';
import 'package:school_nx_pro/provider/school_circular_provider.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_drawer.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_attendance_screen.dart';
import 'package:school_nx_pro/screens/common_screens/holidays_screen.dart';
import 'package:school_nx_pro/screens/common_screens/profile_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_gallery_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/payment_webview_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:intl/intl.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/extension.dart';
import 'package:school_nx_pro/utils/fee_receipt_generator.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

import '../../../provider/auth_provider.dart';
import '../../../utils/ConstantUtils.dart';
import '../../../utils/CustomText.dart';
import '../../../utils/PreferenceUtils.dart';
import '../../../utils/safe_logout.dart';
import '../../auth/login_screen.dart';
import '../../auth/select_institute_screen.dart';
import '../../auth/select_student_screen.dart';
import '../../common_screens/rules_regulation_screen.dart';
import '../../common_screens/school_circular_screen.dart';

enum PaymentMethodOption { upi, card, netBanking }

extension PaymentMethodOptionX on PaymentMethodOption {
  String get displayName {
    switch (this) {
      case PaymentMethodOption.upi:
        return "UPI";
      case PaymentMethodOption.card:
        return "Credit/Debit Card";
      case PaymentMethodOption.netBanking:
        return "Net Banking";
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethodOption.upi:
        return "UPI";
      case PaymentMethodOption.card:
        return "CARD";
      case PaymentMethodOption.netBanking:
        return "NET_BANKING";
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodOption.upi:
        return Icons.qr_code;
      case PaymentMethodOption.card:
        return Icons.credit_card;
      case PaymentMethodOption.netBanking:
        return Icons.account_balance;
    }
  }
}

class ParentDashboard extends StatefulWidget {
  final List<dynamic> children;
  final Map<String, dynamic> loginData;

  const ParentDashboard({super.key, required this.children, required this.loginData});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  // String? parentName;
  String studentId = '';

  ParentDashboardProvider parentDashboardProvider = ParentDashboardProvider();
  late HolidayProviders holidayProvider;
  late HomeworkProviders homeworkProvider;
  late SchoolCircularProvider schoolCircularProvider;

  bool loading = true;
  List<EventGallery> events = [];
  Map<String, dynamic>? _cachedMatchingChild;
  String? _cachedStudentId;
  int? _cachedChildrenLength;

  @override
  void initState() {
    super.initState();
    // Initialize providers immediately
    parentDashboardProvider = Provider.of<ParentDashboardProvider>(context, listen: false);
    holidayProvider = Provider.of<HolidayProviders>(context, listen: false);
    homeworkProvider = Provider.of<HomeworkProviders>(context, listen: false);
    schoolCircularProvider = Provider.of<SchoolCircularProvider>(context, listen: false);
    
    // Load data asynchronously without blocking UI
    _initializeData();



  }
  Map<String, dynamic>? _getMatchingChild() {
    // Only recalculate if studentId or children list changed
    final childrenLength = widget.children.length;
    if (_cachedStudentId != studentId ||
        _cachedMatchingChild == null ||
        _cachedChildrenLength != childrenLength) {
      try {
        _cachedMatchingChild = widget.children.firstWhere(
              (child) => child["studentId"]?.toString() == studentId.toString(),
          orElse: () => <String, dynamic>{},
        );
        _cachedStudentId = studentId;
        _cachedChildrenLength = childrenLength;

        // If empty map, set to null
        if (_cachedMatchingChild != null && _cachedMatchingChild!.isEmpty) {
          _cachedMatchingChild = null;
        }
      } catch (e) {
        _cachedMatchingChild = null;
      }
    }
    return _cachedMatchingChild;
  }
  // Optimized: Load data in background, show UI immediately
  Future<void> _initializeData() async {
    // Get studentId first (fast - from SharedPreferences)
    studentId = await MySharedPreferences.instance.getStringValue('studentId') ?? '';
    
    // Load cached events immediately (if available)
    _loadCachedEvents();
    
    // Show UI immediately with cached data (if available from providers)
    if (mounted) {
      setState(() {
        loading = false;
      });
    }

    // Load fresh data in background (non-blocking)
    _loadDataInBackground();
  }

  // Load cached events from SharedPreferences for instant display
  Future<void> _loadCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEventsJson = prefs.getString('cached_events');
      debugPrint("cachedEventJson : $cachedEventsJson");
      if (cachedEventsJson != null) {
        final List<dynamic> decoded = json.decode(cachedEventsJson);
        final cachedEvents = decoded.map((e) => EventGallery.fromJson(e)).toList();
        if (mounted && cachedEvents.isNotEmpty) {
          setState(() {
            events = cachedEvents;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading cached events: $e");
    }
  }

  // Load all data in parallel without blocking UI
  Future<void> _loadDataInBackground() async {
    try {
      // Load all data in parallel for faster performance
      await Future.wait([
        parentDashboardProvider.getStudentDetails(),
        holidayProvider.getHoliday(),
        homeworkProvider.fetchHomework(studentId),
        schoolCircularProvider.getSchoolCircular(),
        _loadEventData(),
      ]);
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    }
    
    // Update UI when data is ready
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadEventData() async {
    try {
      final loadedEvents = await fetchGalleryData();
      if (mounted) {
        setState(() {
          events = loadedEvents;
        });
        // Cache events for next time
        await _cacheEvents(loadedEvents);
      }
    } catch (e) {
      debugPrint("Error fetching event data: $e");
    }
  }

  // Cache events to SharedPreferences
  Future<void> _cacheEvents(List<EventGallery> eventsToCache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = json.encode(eventsToCache.map((e) => {
        'eventId': e.eventId,
        'eventName': e.eventName,
        'eventDate': e.eventDate,
        'images': e.images,
      }).toList());
      await prefs.setString('cached_events', eventsJson);
    } catch (e) {
      debugPrint("Error caching events: $e");
    }
  }

  // Load gallery data with cache support
  Future<List<EventGallery>> _loadGalleryDataWithCache() async {
    // If we already have events loaded, return them immediately
    if (events.isNotEmpty) {
      return events;
    }
    // Otherwise fetch fresh data
    return await fetchGalleryData();
  }

  // Build gallery grid widget
  Widget _buildGalleryGrid(BuildContext context, List<EventGallery> galleryEvents) {
    final screenSize = MediaQuery.of(context).size;
    double cardHeight = screenSize.height;
    int crossAxisCount;
    double childAspectRatio;

    if (screenSize.width > 800 || screenSize.width >= 800) {
      crossAxisCount = 5;
      childAspectRatio = (cardHeight / crossAxisCount) / 100;
    } else {
      crossAxisCount = 3;
      childAspectRatio = (cardHeight / crossAxisCount) / 500;
    }

    final allImages = galleryEvents
        .expand((event) => event.images.map((image) => {
              "url": image,
              "name": event.eventName,
              "date": event.eventDate,
            }))
        .toList();

    return SizedBox(
      height: 200,
      child: GridView.builder(
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
                                child: Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  img['name']!,
                  style: normalBlack.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> refreshDashboard() async {
    // Refresh all data in parallel
    // await Future.wait([
    //   parentDashboardProvider.getStudentDetails(),
    //   holidayProvider.getHoliday(),
    //   homeworkProvider.fetchHomework(studentId),
    //   schoolCircularProvider.getSchoolCircular(),
    //   _loadEventData(),
    // ]);

    parentDashboardProvider.getStudentDetails();
    holidayProvider.getHoliday();
    homeworkProvider.fetchHomework(studentId);
    schoolCircularProvider.getSchoolCircular();
    _loadEventData();

    if (mounted) {
      setState(() {});
    }
  }

  String formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _createDrawerItem({
    required String image,
    required String text,
    GestureTapCallback? onTap,
    required bool isSelected,
  }) {
    final selectedBgColor = isSelected
        ?  AppColors.blue : Colors.transparent;
    final textColor = isSelected ? AppColors.whiteColor : AppColors.blackColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selectedBgColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 13),
              child: Image.asset(
                image,
                height: 30,
                width: 30,
                color: isSelected ? AppColors.whiteColor : AppColors.blue,
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: CustomText.TextMedium(
                  text,
                  fontSize: 14.0,
                  color: textColor, // Dynamic text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  int selectedIndex = 0;
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
    final matchingChild = _getMatchingChild();
    final studentName = matchingChild?["studentName"]?.toString() ?? "N/A";
    final financialYear = matchingChild?["yearOfAdmission"]?.toString() ?? "N/A";

    // Format date once
    final formattedDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());

    if (PreferenceUtils.getInt(PREF_DRAWER_INDEX) == -1) {
      selectedIndex = 0;
    } else {
      selectedIndex = PreferenceUtils.getInt(PREF_DRAWER_INDEX);
    }

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: ParentAppbar(
        isDash: true,
        onStudentChanged: (String studentId) {
          print("student id onChange : $studentId");
          setState(() {
            loading = true;
          });
          refreshDashboard().then((_) {
            setState(() {
              loading = false;
            });
          });
          log("onStudentChanged executed! New Student ID: $studentId");
        },
      ),
      drawerEnableOpenDragGesture: false,
      // drawer: ParentDrawer(
      //   studentId: studentId,
      //   children: widget.children,
      // ),
      drawer: Padding(
        key: _scaffoldKey,
        padding: EdgeInsets.only(top: 0),
        child: Drawer(
          backgroundColor: AppColors.whiteColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                height: 180,
                padding: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: AppColors.blue, // Dark variant for header
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 20),
                      height: 60,
                      width: 60,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(
                                userType: UserType.parent,
                                name: widget.loginData['userName'] ?? 'N/A',
                                firstName: widget.loginData['firstName'] ?? 'N/A',
                                lastName: widget.loginData['lastName'] ?? 'N/A',
                                mobile: widget.loginData['mobileNo'] ?? "+91",
                                type: 'Parent',
                              ),
                            ),
                          ).then((result) {
                            if (result != null && result is Map<String, dynamic>) {
                              refreshDashboard();
                              setState(() {});
                            }
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            AppImages.example,
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          CustomText.TextRegular(
                            "$studentName",
                            fontSize: 14.0,
                            color: Colors.white, // Keep white for header contrast
                          ),
                          const SizedBox(height: 2),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [

                              CustomText.TextMedium(
                                "Fin. Year : ",
                                fontSize: 14.0,
                                color: Colors.white, // Keep white for header contrast
                              ),
                              const SizedBox(width: 7),
                              CustomText.TextMedium(
                                financialYear,
                                fontSize: 14.0,
                                color: Colors.white, // Keep white for header contrast
                              ),

                            ],
                          ),

                          const SizedBox(height: 5),
                          CustomText.TextMedium(
                            "Date : $formattedDate",
                            fontSize: 12.0,
                            color: Colors.white, // Keep white for header contrast
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              _createDrawerItem(
                image: AppIcons.dashboard,
                text: menuDashboard,
                isSelected: selectedIndex == 0,
                onTap: () {
                  setState(() {
                    selectedIndex = 0;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParentDashboard(
                          loginData: widget.loginData,
                          children: widget.children,
                        ),
                      ),
                          (route) => false,
                    );
                  });
                },
              ),

              _createDrawerItem(
                image: AppIcons.oldReceipt,
                text: menuOldReceipt,
                isSelected: selectedIndex == 1,
                onTap: () {
                  setState(() {
                    selectedIndex = 1;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ParentOldReceiptsScreen(
                        studentId: studentId,
                        studentName: studentName,
                        studentPhone: matchingChild?["phone"]?.toString() ?? "N/A",
                        studentEmail: matchingChild?["email"]?.toString() ?? "N/A",
                      )),
                    );
                  });
                },
              ),
              _createDrawerItem(
                image: AppIcons.attendance,
                text: menuAttendance,
                isSelected: selectedIndex == 2,
                onTap: () {
                  setState(() {
                    selectedIndex = 2;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          AttendanceScreen(userType: UserType.parent, studentId: studentId)
                      ),
                    );
                  });
                },
              ),
              _createDrawerItem(
                image: AppIcons.schoolCircular,
                text: menuEvent,
                isSelected: selectedIndex == 3,
                onTap: () {
                  setState(() {
                    selectedIndex = 3;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          EventScreen(userType: UserType.parent)
                      ),
                    );
                  });
                },
              ),
              _createDrawerItem(
                image: AppIcons.holidays,
                text: menuHoliday,
                isSelected: selectedIndex == 4,
                onTap: () {
                  setState(() {
                    selectedIndex = 4;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          HolidaysScreen(userType: UserType.parent)
                      ),
                    );
                  });
                },
              ),
              _createDrawerItem(
                image: AppIcons.gallery,
                text: menuGallery,
                isSelected: selectedIndex == 5,
                onTap: () {
                  setState(() {
                    selectedIndex = 5;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          ParentGalleryScreen()
                      ),
                    );
                  });
                },
              ),
              _createDrawerItem(
                image: AppIcons.homeWork,
                text: menuHomeWork,
                isSelected: selectedIndex == 6,
                onTap: () {
                  setState(() {
                    selectedIndex = 6;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          ParentHomeworkScreen(userType: UserType.parent, studentId: studentId)
                      ),
                    );
                  });
                },
              ),
              _createDrawerItem(
                image: AppIcons.result,
                text: menuResult,
                isSelected: selectedIndex == 7,
                onTap: () {
                  setState(() {
                    selectedIndex = 7;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          ParentResultScreen()
                      ),
                    );
                  });
                },
              ),
              _createDrawerItem(
                image: AppIcons.rules,
                text: menuRules,
                isSelected: selectedIndex == 8,
                onTap: () {
                  setState(() {
                    selectedIndex = 8;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          RulesRegulationScreen()
                      ),
                    );
                  });
                },
              ),

              _createDrawerItem(
                image: AppIcons.logout,
                text: menuLogout,
                isSelected: selectedIndex == 9,
                onTap: () {
                  setState(() {
                    selectedIndex = 9;
                    PreferenceUtils.saveInt(PREF_DRAWER_INDEX, selectedIndex);
                    Navigator.pop(context);
                    SafeLogout.logout().then((value) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                            (route) => false,
                      );
                    });
                  });
                },
              ),

              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  // Only show switch if user has both roles
                  if (!authProvider.hasParentRole || !authProvider.hasEmployeeRole) {
                    return const SizedBox.shrink();
                  }

                  debugPrint("userType : ${authProvider.userType.toLowerCase()}");

                  final isParent = authProvider.userType.toLowerCase() == 'parent';
                  debugPrint("userType : ${isParent}");
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText.TextMedium(
                          employee,
                          fontSize: 14.0,
                          color: AppColors.blackColor, // Dynamic text color
                        ),

                        Switch(
                          activeColor: AppColors.blue,
                          value: isParent,
                          onChanged: (value) async {
                            // value is true when switching to Parent, false when switching to Employee
                            if (value) {
                              // Switching to Parent role
                              final success = await authProvider.switchRole('parent');
                              if (success && context.mounted) {
                                // Navigate to SelectStudentScreen
                                final loginDataString = await MySharedPreferences.instance
                                    .getStringValue('loginRequestData');
                                if (loginDataString != null) {
                                  try {
                                    final loginData = json.decode(loginDataString) as Map<String, dynamic>;
                                    // Get children from authProvider or SharedPreferences
                                    List<dynamic> children = authProvider.children.isNotEmpty
                                        ? authProvider.children
                                        : [];
                                    if (children.isEmpty) {
                                      final childrenString = await MySharedPreferences.instance
                                          .getStringValue('childrenList');
                                      if (childrenString != null) {
                                        try {
                                          children = json.decode(childrenString);
                                        } catch (e) {
                                          children = [];
                                        }
                                      }
                                    }
                                    if (context.mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SelectStudentScreen(
                                            children: children,
                                            loginData: loginData,
                                          ),
                                        ),
                                            (route) => false,
                                      );
                                    }
                                  } catch (e) {
                                    // Handle error
                                  }
                                }
                              }
                            } else {
                              // Switching to Employee role
                              final success = await authProvider.switchRole('employee');
                              if (success && context.mounted) {
                                // Navigate to SelectInstituteScreen
                                final loginDataString = await MySharedPreferences.instance
                                    .getStringValue('loginRequestData');
                                if (loginDataString != null) {
                                  try {
                                    final loginData = json.decode(loginDataString) as Map<String, dynamic>;
                                    // Use instituteNames from authProvider directly
                                    final institutes = authProvider.instituteNames;
                                    // Get children from authProvider or SharedPreferences
                                    List<dynamic> children = authProvider.children.isNotEmpty
                                        ? authProvider.children
                                        : [];
                                    if (children.isEmpty) {
                                      final childrenString = await MySharedPreferences.instance
                                          .getStringValue('childrenList');
                                      if (childrenString != null) {
                                        try {
                                          children = json.decode(childrenString);
                                        } catch (e) {
                                          children = [];
                                        }
                                      }
                                    }
                                    if (context.mounted) {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SelectInstituteScreen(
                                            institutes: institutes,
                                            children: children,
                                            loginData: loginData,
                                          ),
                                        ),
                                            (route) => false,
                                      );
                                    }
                                  } catch (e) {
                                    // Handle error
                                  }
                                }
                              }
                            }
                          },
                        ),
                        CustomText.TextMedium(
                          parent,
                          fontSize: 14.0,
                          color: AppColors.blackColor, // Dynamic text color
                        ),

                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: loading
          ?  Center(child: Container())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 20),
                        height: 60,
                        width: 60,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userType: UserType.parent,
                                  name: widget.loginData['userName'] ?? 'N/A',
                                  firstName: widget.loginData['firstName'] ?? 'N/A',
                                  lastName: widget.loginData['lastName'] ?? 'N/A',
                                  mobile: widget.loginData['mobileNo'] ?? "+91",
                                  type: 'Parent',
                                ),
                              ),
                            ).then((result) {
                              if (result != null && result is Map<String, dynamic>) {
                                refreshDashboard();
                                setState(() {});
                              }
                            });
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              AppImages.example,
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            CustomText.TextRegular(
                              "$studentName",
                              fontSize: 14.0,
                              color: Colors.black, // Keep white for header contrast
                            ),
                            const SizedBox(height: 2),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [

                                CustomText.TextMedium(
                                  "Fin. Year : ",
                                  fontSize: 14.0,
                                  color: Colors.black, // Keep white for header contrast
                                ),
                                const SizedBox(width: 7),
                                CustomText.TextMedium(
                                  financialYear,
                                  fontSize: 14.0,
                                  color: Colors.black, // Keep white for header contrast
                                ),

                              ],
                            ),

                            const SizedBox(height: 5),
                            CustomText.TextMedium(
                              "Date : $formattedDate",
                              fontSize: 12.0,
                              color: Colors.black, // Keep white for header contrast
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: MediaQuery.of(context).size.height / 5.3,
                    width: double.maxFinite,
                    margin: EdgeInsets.only(left: 20,right: 20),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendanceScreen(userType: UserType.parent, studentId: studentId),
                                    // const ParentAttendanceScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.blue, width: 1),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: CustomText.TextMedium("Total Present Days",textAlign: TextAlign.center),
                                    ),
                                    Divider(color: AppColors.colorDADADA),
                                    const SizedBox(height: 10,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 10.0,),
                                        CustomText.TextMedium(
                                          "263",fontSize: 18.0
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0,),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendanceScreen(userType: UserType.parent, studentId: studentId),
                                    // const ParentAttendanceScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.blue, width: 1),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(
                                      child: CustomText.TextMedium("Total Absent Days",textAlign: TextAlign.center),
                                    ),
                                    Divider(color: AppColors.colorDADADA),
                                    const SizedBox(height: 10,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 20,
                                          width: 20,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10.0,),
                                        CustomText.TextMedium(
                                          "29",
                                          fontSize: 18.0,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    transform: Matrix4.translationValues(0.0, -25.0, 0.0),
                    // height: MediaQuery.of(context).size.height / 1.2,
                    width: double.maxFinite,
                    decoration: const BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText.TextMedium("Fee Details", fontSize: 18.0, )),
                          SizedBox(height: 10),
                          dueFeesCard(context, parentDashboardProvider,studentName),
                          SizedBox(height: 20),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Home Work", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600))),
                          SizedBox(height: 10),
                          Consumer<HomeworkProviders>(
                            builder: (context, homeworkProviders, child) {
                              // Show cached data immediately, only show spinner if no data at all
                              final hw = homeworkProviders.homework;
                              if (hw == null) {
                                // Only show loading if we're loading AND have no cached data
                                if (homeworkProviders.isLoading && homeworkProviders.homeworkList.isEmpty) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                return const Center(child: Text("No homework found"));
                              }

                              return Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.white,
                                  // border: Border.all(color: AppColors.blue, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue,
                                        borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7))
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomText.TextSemiBold(hw.subjectName,fontSize: 14.0,color: AppColors.whiteColor),
                                          CustomText.TextSemiBold(formatDate(hw.homeWorkDate),fontSize: 14.0,color: AppColors.whiteColor),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: _rowItem("Title", hw.homeWorkName),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: _rowItem("Due On", formatDate(hw.homeWorkDueOnDate)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),

                          Row(
                            children: [

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) =>
                                          HolidaysScreen(userType: UserType.parent)
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.colorDADADA, width: 1),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppIcons.holidays,
                                          height: 30,
                                          width: 30,
                                          color: AppColors.blue,
                                        ),
                                        const SizedBox(height: 5,),
                                        CustomText.TextMedium(
                                          menuHoliday,
                                          fontSize: 14.0,
                                          color: AppColors.blackColor, // Dynamic text color
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 20,),

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) =>
                                          EventScreen(userType: UserType.parent)
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.colorDADADA, width: 1),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppIcons.schoolCircular,
                                          height: 30,
                                          width: 30,
                                          color: AppColors.blue,
                                        ),
                                        const SizedBox(height: 5,),
                                        CustomText.TextMedium(
                                          menuEvent,
                                          fontSize: 14.0,
                                          color: AppColors.blackColor, // Dynamic text color
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              )

                            ],
                          ),

                          const SizedBox(height: 20,),

                          Row(
                            children: [

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) =>
                                          ParentGalleryScreen()
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.colorDADADA, width: 1),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppIcons.gallery,
                                          height: 30,
                                          width: 30,
                                          color: AppColors.blue,
                                        ),
                                        const SizedBox(height: 5,),
                                        CustomText.TextMedium(
                                          menuGallery,
                                          fontSize: 14.0,
                                          color: AppColors.blackColor, // Dynamic text color
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 20,),

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) =>
                                          ParentResultScreen()
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.colorDADADA, width: 1),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppIcons.result,
                                          height: 30,
                                          width: 30,
                                          color: AppColors.blue,
                                        ),
                                        const SizedBox(height: 5,),
                                        CustomText.TextMedium(
                                          menuResult,
                                          fontSize: 14.0,
                                          color: AppColors.blackColor, // Dynamic text color
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          ),

                          // Align(
                          //     alignment: Alignment.centerLeft,
                          //     child: Text("Holidays", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600))),
                          // SizedBox(height: 10),
                          // Selector<HolidayProviders, List<HolidayModels>>(
                          //   selector: (p0, p1) => p1.getHolidayList,
                          //   builder: (context, holidayList, child) {
                          //     return holidayList.isEmpty
                          //         ? const Center(
                          //             child: Text("No Data Awailable", style: TextStyle(color: Colors.black),),
                          //           )
                          //         : SizedBox(
                          //       height: 160,
                          //       child: ListView.builder(
                          //       itemCount: holidayList.length,
                          //         itemBuilder: (context, index) {
                          //         final holiday = holidayList[index];
                          //         return Card(
                          //           margin: const EdgeInsets.symmetric(vertical: 5),
                          //           elevation: 2,
                          //           shape: RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.circular(25),
                          //             side: const BorderSide(color: AppColors.blue),
                          //           ),
                          //           child: Container(
                          //             width: double.infinity,
                          //             decoration: const BoxDecoration(
                          //               color: Colors.white,
                          //               borderRadius: BorderRadius.all(Radius.circular(25)),
                          //             ),
                          //             child: IntrinsicHeight(
                          //               child: Row(
                          //                 crossAxisAlignment: CrossAxisAlignment.start,
                          //                 children: [
                          //                   Container(
                          //                     width: MediaQuery.of(context).size.width / 2.8,
                          //                     decoration: const BoxDecoration(
                          //                       color: AppColors.blue,
                          //                       borderRadius: BorderRadius.all(Radius.circular(25)),
                          //                     ),
                          //                     child: Center(
                          //                       child: Text(holiday.holidayOn,
                          //                         textAlign: TextAlign.center,
                          //                         style: normalWhite.copyWith(
                          //                           fontWeight: FontWeight.w700,
                          //                         ),
                          //                       ),
                          //                     ),
                          //                   ),
                          //                   Expanded(
                          //                     child: Padding(
                          //                       padding: const EdgeInsets.symmetric(vertical: 10),
                          //                       child: Column(
                          //                         crossAxisAlignment: CrossAxisAlignment.center,
                          //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //                         mainAxisSize: MainAxisSize.max,
                          //                         children: [
                          //                           Padding(
                          //                             padding: const EdgeInsets.symmetric(horizontal: 2),
                          //                             child: Text(holiday.reason,
                          //                               textAlign: TextAlign.center,
                          //                               style: normalBlack.copyWith(
                          //                                 fontWeight: FontWeight.w700,
                          //                               ),
                          //                             ),
                          //                           ),
                          //                         ],
                          //                       ),
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         );
                          //       },
                          //       ),
                          //     );
                          //   },
                          // ),
                          // SizedBox(height: 20),
                          // Align(
                          //     alignment: Alignment.centerLeft,
                          //     child: Text("Events", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600))),
                          // SizedBox(height: 10),
                          // // Show cached events immediately, update when new data arrives
                          // events.isEmpty
                          //     ? const Center(child: Text("No data available"))
                          //     : SizedBox(
                          //   height: 100,
                          //       child: ListView.builder(
                          //         itemCount: events.length,
                          //         itemBuilder: (context, index) {
                          //           final event = events[index];
                          //           return AppCard(
                          //             mainTitle: event.eventDate,
                          //             upperTitle: event.eventName,
                          //             widget: Text(
                          //               event.eventDate,
                          //               style: normalBlack,
                          //             ),
                          //           );
                          //         },
                          //       ),
                          //     ),
                          // SizedBox(height: 20),
                          // Align(
                          //     alignment: Alignment.centerLeft,
                          //     child: Text("Gallery", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600))),
                          // SizedBox(height: 10),
                          // // Show cached events immediately, refresh in background
                          // FutureBuilder<List<EventGallery>>(
                          //   future: _loadGalleryDataWithCache(),
                          //   builder: (context, snapshot) {
                          //     // Show cached data immediately if available
                          //     if (snapshot.connectionState == ConnectionState.waiting && events.isEmpty) {
                          //       return const Center(child: CircularProgressIndicator());
                          //     } else if (snapshot.hasError) {
                          //       // On error, show cached events if available
                          //       if (events.isNotEmpty) {
                          //         return _buildGalleryGrid(context, events);
                          //       }
                          //       return Center(child: Text('Error: ${snapshot.error}'));
                          //     } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          //       // If no new data but we have cached events, show them
                          //       if (events.isNotEmpty) {
                          //         return _buildGalleryGrid(context, events);
                          //       }
                          //       return const Center(child: Text("No gallery data available"));
                          //     }
                          //
                          //     final galleryEvents = snapshot.data!;
                          //     // Update cached events
                          //     if (mounted) {
                          //       WidgetsBinding.instance.addPostFrameCallback((_) {
                          //         if (mounted) {
                          //           setState(() {
                          //             events = galleryEvents;
                          //           });
                          //         }
                          //       });
                          //       // Cache events for next time (fire and forget)
                          //       _cacheEvents(galleryEvents);
                          //     }
                          //
                          //     return _buildGalleryGrid(context, galleryEvents);
                          //   },
                          // ),
                          // SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _rowItem(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: CustomText.TextSemiBold("$title :", )),
          Expanded(flex: 4, child: CustomText.TextRegular(value ?? "-")),
        ],
      ),
    );
  }

  Card dueFeesCard(
    BuildContext context,
    ParentDashboardProvider provider, String studentName,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.blue),
      ),
      child: Consumer<ParentDashboardProvider>(
        builder: (context, student, child) {
          return Container(
            height: MediaQuery.of(context).size.height / 9.5,
            width: double.maxFinite,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      // student.studentDetails?.studentDetails.studentName ?? "N/A",
                      studentName ?? "N/A",
                      style: boldBlack,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      CustomText.TextMedium(
                          "Net Due",
                      ),
                      student.studentDetails?.totalDue.remainingAmount.toString() == null ?
                          Container() :
                      CustomText.TextMedium(
                        "₹ ${student.studentDetails?.totalDue.remainingAmount.toString()}",
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    debugPrint("Student Details : ${student.studentDetails}");

                    showFeesPaymentPopup(
                      context,
                      provider,
                      "",
                        // student.studentDetails?.totalDue.remainingAmount.toString()
                    );
                  },
                  child: Container(
                    height: 50,
                    margin: EdgeInsets.only(right: 10),
                    width: MediaQuery.of(context).size.width / 4.3,
                    decoration: const BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.all(
                        Radius.circular(25),
                      ),
                    ),
                    child: Center(
                      child: CustomText.TextMedium(
                        "Pay",
                        fontSize: 15.0,
                        color: AppColors.whiteColor
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void showFeesPaymentPopup(
    BuildContext context,
    ParentDashboardProvider provider,
    String totalDue,
  ) {
    final rootContext = context;
    DateTime? selectedDate = DateTime.now();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    dateController.text = selectedDate.toDDMMYYYY();

    showDialog(
      context: rootContext,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 5, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fees Payment',
                          style: boldBlack,
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.black54,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Total Due : ",
                          style: boldBlack.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        TextSpan(
                          text: totalDue,
                          style: normalBlack.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  AppTextField(
                    labelText: 'Online Pay Amount',
                    controller: amountController,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          buttonText: "Cancel",
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onTap: () {
                            Navigator.pop(dialogContext);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: AppButton(
                          buttonText: "Pay",
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onTap: () {
                            final enteredAmount = amountController.text.trim();
                            final parsedAmount = double.tryParse(enteredAmount);

                            if (enteredAmount.isEmpty) {
                              scaffoldMessage(message: "Please enter amount");
                              return;
                            }

                            if (parsedAmount == null || parsedAmount <= 0) {
                              scaffoldMessage(
                                message: "Please enter a valid amount",
                              );
                              return;
                            }

                            Navigator.of(dialogContext).pop();

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _showPaymentMethodSheet(
                                parentContext: rootContext,
                                provider: provider,
                                amount: enteredAmount,
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ]
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                        child: e,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        );
      },
    );
  }

  void _showPaymentMethodSheet({
    required BuildContext parentContext,
    required ParentDashboardProvider provider,
    required String amount,
  }) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "Select Payment Method",
                  style: boldBlack,
                ),
              ),
              ...PaymentMethodOption.values.map(
                (method) => ListTile(
                  leading: Icon(method.icon, color: AppColors.blue),
                  title: Text(method.displayName),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _processPayment(
                      parentContext,
                      provider,
                      amount,
                      method,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    ParentDashboardProvider provider,
    String amount,
    PaymentMethodOption method,
  ) async {
    final parsedAmount = double.tryParse(amount) ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String? paymentUrl;

    try {
      paymentUrl = await provider.addPayment(
        paymentAmount: amount,
        paymentMethod: method.apiValue,
      );
    } catch (e, stackTrace) {
      log("Payment processing failed: $e", name: '_processPayment');
      log(stackTrace.toString(), name: '_processPayment stack');
      scaffoldMessage(message: "Unable to start payment. Please try again.");
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (paymentUrl == null || !mounted) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl!),
      ),
    );

    if (!mounted) return;

    if (result == "success") {
      final studentName =
          provider.studentDetails?.studentDetails.studentName ?? "Student";
      final transactionId = "TXN${DateTime.now().millisecondsSinceEpoch}";

      await generateFeeReceipt(
        studentName: studentName,
        amount: parsedAmount,
        transactionId: transactionId,
        paymentMode: method.displayName,
        paymentDate: DateTime.now(),
      );

      scaffoldMessage(message: "Payment Successful");
      await provider.getStudentDetails();
      setState(() {});
    } else if (result == "failure") {
      scaffoldMessage(message: "Payment Failed");
    } else {
      scaffoldMessage(message: "Payment cancelled");
    }
  }
}
