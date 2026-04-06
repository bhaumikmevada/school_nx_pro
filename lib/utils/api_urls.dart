class ApiUrls {
  // Staging Base URL
  static String baseUrl = "https://api.schoolnxpro.com/api/";

  // auth
  static const login = "Registration/login";
  static const refreshToken = "user/refresh_token";

  static const schoolcircular = 'EventwithImage';
  static const holiday = 'holiday';
  static const homework = 'Homework';
  static const subject = 'Subject';
  static const addHomework = 'HomeworkUpload1/add';

  // Results
  static const termname = 'termname';
  static const examname = 'examname';
  static const result = 'marksheet/marks/';

  static const oldreciept = 'oldreciept';
  static const schoolDetails = 'SchoolDetails/1';

  // Payment
  static const getPaymentDetails = 'SchoolFees1/StudentFeeDetails';
  static const addPayment = 'SchoolFess4/ProcessPayment';

  // Attendance
  static const course = 'course';
  static const section = 'section';
  static const medium = 'medium';
  static const stream = 'stream';
  static const substream = 'substream';
  static const studentInCSMSS = 'studentInCSMSS/Students';
  // static const submitAttandancewithCSMSS = 'submitAttandancewithCSMSS';
  static const submitAttandancewithCSMSS = 'SubmitAttendance';
}
