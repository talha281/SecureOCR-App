# ProGuard / R8 Keep Rules for SecureCode OCR

# ML Kit Text Recognition ProGuard rules
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.vision.common.**
-dontwarn com.google.mlkit.common.**
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Flutter Play Core & Deferred Components suppress warnings
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep Flutter & Riverpod
-keep class io.flutter.** { *; }
-keep class com.google.android.gms.** { *; }
