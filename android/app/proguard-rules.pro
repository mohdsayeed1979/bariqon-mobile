# Release-build keep rules, per the Android hardening/release-checklist pass.
# Most Flutter plugins ship their own consumer-rules.pro that AGP merges
# automatically when minification is on, so this file is a defensive
# baseline for the specific plugin families this app depends on
# (supabase_flutter's networking stack, flutter_secure_storage, local_auth)
# rather than an exhaustive list — reduces risk without assuming it
# eliminates it; see the release-hardening report for the on-device
# regression testing this still needs before shipping.

# Flutter engine/plugin glue.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Play Core — referenced by Flutter's deferred-components support even
# though this app doesn't use split delivery.
-dontwarn com.google.android.play.core.**

# Gson — used transitively by some networking plugins for JSON (de)serialization.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp / Okio — used transitively by supabase_flutter's networking stack.
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# flutter_secure_storage — App Lock PIN storage.
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# local_auth — App Lock biometric prompt.
-keep class androidx.biometric.** { *; }
