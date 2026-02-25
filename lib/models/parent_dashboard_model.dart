//khushi
class StudentDetailsModel {
  final String academicYear;
  final StudentDetails studentDetails;
  final List<FeeDetail> feeDetails;
  final TotalDue totalDue;
  final String yearOfAdmission;

  StudentDetailsModel({
    required this.academicYear, required this.yearOfAdmission,
    required this.studentDetails,
    required this.feeDetails,
    required this.totalDue,
  });

  factory StudentDetailsModel.fromJson(Map<String, dynamic> json) {
    return StudentDetailsModel(
      academicYear: json['academicYear'],
      yearOfAdmission: json['yearOfAdmission'],
      studentDetails: StudentDetails.fromJson(json["studentDetails"]),
      feeDetails: List<FeeDetail>.from(
        json["feeDetails"].map((x) => FeeDetail.fromJson(x)),
      ),
      totalDue: TotalDue.fromJson(json["totalDue"]),
    );
  }
}

class FeeDetail {
  final String studentName;
  final String fathersname;
  final String feeType;
  final int totalInvoice;
  final int totalDue;
  final int totalReceipt;
  final String currentSectionName;
  final DateTime accountingVoucherDate;
  final String sessionYear;
  final String currentCourseName;

  FeeDetail({
    required this.studentName,
    required this.fathersname,
    required this.feeType,
    required this.totalInvoice,
    required this.totalDue,
    required this.totalReceipt,
    required this.currentSectionName,
    required this.accountingVoucherDate,
    required this.sessionYear,
    required this.currentCourseName,
  });

  factory FeeDetail.fromJson(Map<String, dynamic> json) => FeeDetail(
        studentName: json["studentName"],
        fathersname: json["fathersname"],
        feeType: json["feeType"],
        totalInvoice: json["totalInvoice"],
        totalDue: json["totalDue"],
        totalReceipt: json["totalReceipt"],
        currentSectionName: json["currentSectionName"],
        accountingVoucherDate: DateTime.parse(json["accountingVoucherDate"]),
        sessionYear: json["sessionYear"],
        currentCourseName: json["currentCourseName"],
      );
}

class StudentDetails {
  final String studentName;
  final String fathersname;
  final String currentSectionName;
  final String currentCourseName;
  final String sessionYear;

  StudentDetails({
    required this.studentName,
    required this.fathersname,
    required this.currentSectionName,
    required this.currentCourseName,
    required this.sessionYear,
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) => StudentDetails(
        studentName: json["studentName"],
        fathersname: json["fathersname"],
        currentSectionName: json["currentSectionName"],
        currentCourseName: json["currentCourseName"],
        sessionYear: json["sessionYear"],
      );
}

class TotalDue {
  final int totalDueForAllFeeTypesInvoice;
  final int totalPaidForAllFeeTypesDue;
  final int totalReciept;
  final int remainingAmount;
  final List<FeeInvoiceTypeDetail> feeInvoiceTypeDetails;

  TotalDue({
    required this.totalDueForAllFeeTypesInvoice,
    required this.totalPaidForAllFeeTypesDue,
    required this.totalReciept,
    required this.remainingAmount,
    required this.feeInvoiceTypeDetails,
  });

  factory TotalDue.fromJson(Map<String, dynamic> json) => TotalDue(
        totalDueForAllFeeTypesInvoice: json["totalDueForAllFeeTypesInvoice"],
        totalPaidForAllFeeTypesDue: json["totalPaidForAllFeeTypesDue"],
        totalReciept: json["totalReciept"],
        remainingAmount: json["remainingAmount"],
        feeInvoiceTypeDetails: List<FeeInvoiceTypeDetail>.from(
            json["feeInvoiceTypeDetails"]
                .map((x) => FeeInvoiceTypeDetail.fromJson(x))),
      );
}

class FeeInvoiceTypeDetail {
  final String feeType;
  final int totalFeeTypeInvoice;
  final int totalFeeTypeDue;
  final int totalFeeTypeReciept;

  FeeInvoiceTypeDetail({
    required this.feeType,
    required this.totalFeeTypeInvoice,
    required this.totalFeeTypeDue,
    required this.totalFeeTypeReciept,
  });

  factory FeeInvoiceTypeDetail.fromJson(Map<String, dynamic> json) =>
      FeeInvoiceTypeDetail(
        feeType: json["feeType"],
        totalFeeTypeInvoice: json["totalFeeTypeInvoice"],
        totalFeeTypeDue: json["totalFeeTypeDue"],
        totalFeeTypeReciept: json["totalFeeTypeReciept"],
      );
}
