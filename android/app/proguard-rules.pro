# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep ML Kit Text Recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# Keep Chinese text recognition
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**

# Keep Devanagari text recognition
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-dontwarn com.google.mlkit.vision.text.devanagari.**

# Keep Japanese text recognition
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-dontwarn com.google.mlkit.vision.text.japanese.**

# Keep Korean text recognition
-keep class com.google.mlkit.vision.text.korean.** { *; }
-dontwarn com.google.mlkit.vision.text.korean.**

# If you are only using Latin script (English), you can be more specific:
# -keep class com.google.mlkit.vision.text.latin.** { *; }

# Keep common ML Kit classes
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }
