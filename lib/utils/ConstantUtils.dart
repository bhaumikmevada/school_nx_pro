import 'package:school_nx_pro/utils/api_urls.dart';

const String PREF_DRAWER_INDEX = "PREF_DRAWER_INDEX";

const String payUMerchantKey = 'RjOj6j';
// "1" = Test/Staging, "0" = Production
const String payUEnvironment = "1";
const String payUAndroidSurl = 'https://onion-only-refurbish.ngrok-free.dev/payment-success';
const String payUAndroidFurl = 'https://onion-only-refurbish.ngrok-free.dev/payment-failure';
const String payUIosSurl = 'https://onion-only-refurbish.ngrok-free.dev/payment-success';
const String payUIosFurl = 'https://onion-only-refurbish.ngrok-free.dev/payment-failure';
final String payUHashGenerationApiUrl = ApiUrls.payUGenerateHash;



