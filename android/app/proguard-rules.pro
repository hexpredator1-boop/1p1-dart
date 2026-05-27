# Keep Google Play Core classes to prevent R8 shrinking errors
# These classes are referenced by Flutter but not used in this simple app
-keep class com.google.android.play.core.** { *; }
