class ApiUrls {
  // Staging Base URL
  // static String baseUrl = "https://api.schoolnxpro.com/api/";
  static String baseUrl = "http://103.97.47.241:8098/school_api/api/";

  // auth
  // static const login = "Registration/login";
  static const login = "login";
  static const refreshToken = "user/refresh_token";

  // static const schoolcircular = 'EventwithImage';
  static const schoolcircular = 'events/with-images';
  static const holiday = 'holiday';
  static const homework = 'Homework';
  static const subject = 'Subject';
  static const addHomework = 'HomeworkUpload1/add';
  static const studentAttendanceUrl = "attendance/student";
  static const myHomework = "homework/my";
  static const dashboard = "dashboard/my";

  // Results
  static const termname = 'termname';
  static const examname = 'examname';
  static const result = 'marksheet/marks/';

  static const oldreciept = 'oldreciept';
  static const schoolDetails = 'SchoolDetails/1';

  // Payment
  static const getPaymentDetails = 'SchoolFees1/StudentFeeDetails';
  static const addPayment = 'SchoolFess5/ProcessPayment';

  // Attendance
  static const course = 'course';
  static const section = 'section';
  static const medium = 'medium';
  static const stream = 'stream';
  static const substream = 'substream';
  // static const studentInCSMSS = 'studentInCSMSS/Students';
  static const studentInCSMSS = 'student-in-csmss/students';
  // static const submitAttandancewithCSMSS = 'submitAttandancewithCSMSS';
  // static const submitAttandancewithCSMSS = 'SubmitAttendance';
  static const submitAttandancewithCSMSS = 'submit-attendance';
}
