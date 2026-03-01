# Keep Jitsi Meet SDK classes
-keep class org.jitsi.** { *; }
-keep class org.webrtc.** { *; }

# Keep Facebook Fresco/ImagePipeline classes (used by Jitsi)
-dontwarn com.facebook.imagepipeline.**
-keep class com.facebook.imagepipeline.** { *; }
-dontwarn com.facebook.imagepipeline.nativecode.**

# Keep ReactNative classes (used by Jitsi)
-dontwarn com.facebook.react.**
-keep class com.facebook.react.** { *; }

# Keep Hermes engine (used by Jitsi's React Native)
-dontwarn com.facebook.hermes.**
-keep class com.facebook.hermes.** { *; }

# General Android keep rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
