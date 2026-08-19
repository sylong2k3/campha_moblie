# Mapbox Maps SDK ProGuard Rules
-keep class com.mapbox.** { *; }
-keep interface com.mapbox.** { *; }
-keep enum com.mapbox.** { *; }
-dontwarn com.mapbox.**

# Mapbox Native Libraries & JNI C++ Bindings
-keepclasseswithmembernames class * {
    native <methods>;
}

# flutter_local_notifications serialize model qua Gson + TypeToken; R8 xoá generic
# signature và đổi tên field sẽ làm scheduled/persisted notification hỏng lúc chạy.
# Chỉ giữ phần Gson thật sự phản chiếu tới: model (tên field là khoá JSON) và
# factory đăng ký subtype. Các class còn lại của plugin vẫn reachable qua
# plugin registry nên R8 tự giữ.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.RuntimeTypeAdapterFactory { *; }
# Signature: anonymous TypeToken<...>{} cần generic signature để Gson resolve kiểu.
# RuntimeVisibleAnnotations: NotificationDetails dùng @SerializedName.
-keepattributes Signature,RuntimeVisibleAnnotations

# Network, Dio, OkHttp & Cronet Rules
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }
-keep class org.chromium.** { *; }
-keep interface org.chromium.** { *; }
-keep class com.google.android.gms.net.** { *; }
-dontwarn org.chromium.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Sqflite & Flutter Plugin Rules
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**


