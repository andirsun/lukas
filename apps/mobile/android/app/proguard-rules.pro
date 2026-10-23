# Vosk calls its native library through JNA, which finds classes, fields and methods by name: R8
# must not rename or remove them, or Vosk fails when the model loads (voice spike report, notes for
# Task 12).
-keep class com.sun.jna.** { *; }
-keep class * implements com.sun.jna.** { *; }
-keep class org.vosk.** { *; }
-dontwarn java.awt.**
