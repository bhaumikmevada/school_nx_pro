/// Models for the new Login API response.
///
/// Sample response handled by this model:
/// {
///   "success": true,
///   "message": "Login Successful",
///   "token": "...",
///   "user": { "mobile_no": "...", "User_ID": "...", "User_Owner": "...", "database": "..." },
///   "user_details": { "Institute_ID": "...", "Institute_Name": "...", "User_Type": "Employee", ... },
///   "user_master": null
/// }
class LoginResponseModel {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;
  final UserDetailModel? userDetails;
  final dynamic userMaster;

  LoginResponseModel({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.userDetails,
    this.userMaster,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString(),
      user: json['user'] != null && json['user'] is Map
          ? UserModel.fromJson(Map<String, dynamic>.from(json['user']))
          : null,
      userDetails: json['user_details'] != null && json['user_details'] is Map
          ? UserDetailModel.fromJson(
              Map<String, dynamic>.from(json['user_details']))
          : null,
      userMaster: json['user_master'],
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'token': token,
        'user': user?.toJson(),
        'user_details': userDetails?.toJson(),
        'user_master': userMaster,
      };
}

/// Corresponds to the top-level "user" object.
class UserModel {
  final String mobileNo;
  final String userId;
  final String userOwner;
  final String database;

  UserModel({
    this.mobileNo = '',
    this.userId = '',
    this.userOwner = '',
    this.database = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      mobileNo: json['mobile_no']?.toString() ?? '',
      userId: json['User_ID']?.toString() ?? '',
      userOwner: json['User_Owner']?.toString() ?? '',
      database: json['database']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'mobile_no': mobileNo,
        'User_ID': userId,
        'User_Owner': userOwner,
        'database': database,
      };
}

/// Corresponds to the "user_details" object.
class UserDetailModel {
  final String instituteId;
  final String instituteName;
  final String userDetailId;
  final String userId;
  final String userType; // "Employee" / "Parent" / "Admin" etc.
  final String userName;
  final String instituteUserId;
  final String createdByInstituteUserId;
  final String createdOnDate;
  final String ownerId;
  final String currentSessionYear;
  final String todayDate;
  final String currentFinancialYearStart;
  final String currentFinancialYearEnd;
  final String address;
  final String contactNo;
  final String mobileNo;
  final String affiliationNo;
  final String affiliationNo2;
  final String emailAddress;
  final String webAddress;
  final String principalName;
  final String auditorName;
  final String registrationNo;
  final String other;
  final String punchLine1;
  final String punchLine2;
  final String punchLine3;
  final String diseCode;
  final String instituteNameShort;
  final String cityId;
  final String cityName;
  final String minimumInstituteId;
  final String studentLockLimit;
  final String dateLockLimit;
  final String userLockLimit;
  final String active;
  final String countFormSubmitted;
  final String countUser;
  final String systemDate;
  final String lock;

  UserDetailModel({
    this.instituteId = '',
    this.instituteName = '',
    this.userDetailId = '',
    this.userId = '',
    this.userType = '',
    this.userName = '',
    this.instituteUserId = '',
    this.createdByInstituteUserId = '',
    this.createdOnDate = '',
    this.ownerId = '',
    this.currentSessionYear = '',
    this.todayDate = '',
    this.currentFinancialYearStart = '',
    this.currentFinancialYearEnd = '',
    this.address = '',
    this.contactNo = '',
    this.mobileNo = '',
    this.affiliationNo = '',
    this.affiliationNo2 = '',
    this.emailAddress = '',
    this.webAddress = '',
    this.principalName = '',
    this.auditorName = '',
    this.registrationNo = '',
    this.other = '',
    this.punchLine1 = '',
    this.punchLine2 = '',
    this.punchLine3 = '',
    this.diseCode = '',
    this.instituteNameShort = '',
    this.cityId = '',
    this.cityName = '',
    this.minimumInstituteId = '',
    this.studentLockLimit = '',
    this.dateLockLimit = '',
    this.userLockLimit = '',
    this.active = '',
    this.countFormSubmitted = '',
    this.countUser = '',
    this.systemDate = '',
    this.lock = '',
  });

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    String s(String key) => json[key]?.toString() ?? '';
    return UserDetailModel(
      instituteId: s('Institute_ID'),
      instituteName: s('Institute_Name'),
      userDetailId: s('User_Detail_ID'),
      userId: s('User_ID'),
      userType: s('User_Type'),
      userName: s('User_Name'),
      instituteUserId: s('Institute_User_ID'),
      createdByInstituteUserId: s('Created_By_Institute_User_ID'),
      createdOnDate: s('Created_On_Date'),
      ownerId: s('Owner_ID'),
      currentSessionYear: s('CurrentSessionYear'),
      todayDate: s('TodayDate'),
      currentFinancialYearStart: s('CurrentFinancialYearStart'),
      currentFinancialYearEnd: s('CurrentFinancialYearEnd'),
      address: s('Address'),
      contactNo: s('ContactNo'),
      mobileNo: s('MobileNo'),
      affiliationNo: s('AffiliationNo'),
      affiliationNo2: s('AffiliationNo2'),
      emailAddress: s('EmailAddress'),
      webAddress: s('WebAddress'),
      principalName: s('PrincipalName'),
      auditorName: s('AuditorName'),
      registrationNo: s('RegistrationNo'),
      other: s('Other'),
      punchLine1: s('PunchLine1'),
      punchLine2: s('PunchLine2'),
      punchLine3: s('PunchLine3'),
      diseCode: s('DiseCode'),
      instituteNameShort: s('Institute_Name_Short'),
      cityId: s('City_ID'),
      cityName: s('CityName'),
      minimumInstituteId: s('MinimumInstituteID'),
      studentLockLimit: s('StudentLock_Limit'),
      dateLockLimit: s('DateLock_Limit'),
      userLockLimit: s('UserLock_Limit'),
      active: s('Active'),
      countFormSubmitted: s('CountFormSubmitted'),
      countUser: s('CountUser'),
      systemDate: s('SystemDate'),
      lock: s('Lock'),
    );
  }

  Map<String, dynamic> toJson() => {
        'Institute_ID': instituteId,
        'Institute_Name': instituteName,
        'User_Detail_ID': userDetailId,
        'User_ID': userId,
        'User_Type': userType,
        'User_Name': userName,
        'Institute_User_ID': instituteUserId,
        'Created_By_Institute_User_ID': createdByInstituteUserId,
        'Created_On_Date': createdOnDate,
        'Owner_ID': ownerId,
        'CurrentSessionYear': currentSessionYear,
        'TodayDate': todayDate,
        'CurrentFinancialYearStart': currentFinancialYearStart,
        'CurrentFinancialYearEnd': currentFinancialYearEnd,
        'Address': address,
        'ContactNo': contactNo,
        'MobileNo': mobileNo,
        'AffiliationNo': affiliationNo,
        'AffiliationNo2': affiliationNo2,
        'EmailAddress': emailAddress,
        'WebAddress': webAddress,
        'PrincipalName': principalName,
        'AuditorName': auditorName,
        'RegistrationNo': registrationNo,
        'Other': other,
        'PunchLine1': punchLine1,
        'PunchLine2': punchLine2,
        'PunchLine3': punchLine3,
        'DiseCode': diseCode,
        'Institute_Name_Short': instituteNameShort,
        'City_ID': cityId,
        'CityName': cityName,
        'MinimumInstituteID': minimumInstituteId,
        'StudentLock_Limit': studentLockLimit,
        'DateLock_Limit': dateLockLimit,
        'UserLock_Limit': userLockLimit,
        'Active': active,
        'CountFormSubmitted': countFormSubmitted,
        'CountUser': countUser,
        'SystemDate': systemDate,
        'Lock': lock,
      };
}
