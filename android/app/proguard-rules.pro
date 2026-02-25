# Keep PayU and GPay classes
-keep class com.payu.** { *; }
-dontwarn com.payu.**
-keep class com.google.android.apps.nbu.paisa.** { *; }

# Keep XML stream classes (used by Tika)
-keep class javax.xml.stream.** { *; }
-keep class org.apache.tika.** { *; }

# Prevent warnings about missing classes
-dontwarn javax.xml.stream.**
-dontwarn org.apache.tika.**
-dontwarn com.google.android.apps.nbu.paisa.**

# Keep annotations
-keepattributes *Annotation*

# Keep connectivity_plus classes for release builds
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**