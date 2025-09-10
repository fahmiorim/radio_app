# ===== Flutter/Android base =====
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ===== Google/Firebase (jika dipakai) =====
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ===== SLF4J binding (hindari Missing class StaticLoggerBinder) =====
-keep class org.slf4j.** { *; }
-dontwarn org.slf4j.**
-keep class org.slf4j.impl.** { *; }
-dontwarn org.slf4j.impl.**

# (Opsional jika transitif bawa logback/commons-logging)
-dontwarn ch.qos.logback.**
-dontwarn org.apache.commons.logging.**
