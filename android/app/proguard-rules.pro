# Keep Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
# Keep Firebase / Google Sign-In (reflection)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
# Keep Play Core deferred components (only referenced, not bundled)
-dontwarn com.google.android.play.core.**
