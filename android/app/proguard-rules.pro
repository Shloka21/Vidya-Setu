# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**

# Facebook Fresco (used by some image libraries)
-dontwarn com.facebook.imagepipeline.**
-dontwarn com.facebook.drawee.**

# Giphy SDK
-dontwarn com.giphy.sdk.**
-keep class com.giphy.sdk.** { *; }

# Kotlinx Parcelize
-dontwarn kotlinx.parcelize.**

# Jitsi Meet
-keep class org.jitsi.meet.** { *; }
-keep class org.jitsi.meet.sdk.** { *; }
-dontwarn org.jitsi.**

# WebRTC
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
