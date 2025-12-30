# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**

# 🔥 CallKit Incoming - CRITICAL
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keep interface com.hiennv.flutter_callkit_incoming.** { *; }
-keep class com.hiennv.flutter_callkit_incoming.CallkitIncomingActivity { *; }
-keep class com.hiennv.flutter_callkit_incoming.CallkitNotificationService { *; }
-keep class com.hiennv.flutter_callkit_incoming.CallkitIncomingBroadcastReceiver { *; }
-keep class com.hiennv.flutter_callkit_incoming.entities.** { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**

# 🔥 WorkManager - CRITICAL
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-dontwarn androidx.work.**

# Phone State
-keep class me.sodipto.phone_state.** { *; }
-dontwarn me.sodipto.phone_state.**

# Contacts
-keep class dev.fluttercommunity.plus.contacts.** { *; }
-dontwarn dev.fluttercommunity.plus.contacts.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <methods>;
    @com.google.firebase.firestore.ServerTimestamp <methods>;
}
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# Firebase Auth
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Retrofit (if you use it)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Your App Models
-keep class com.app.secureconnect.models.** { *; }
-keepclassmembers class com.app.secureconnect.models.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Service Locator
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Enum
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# General
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic
-keepattributes *Annotation*

# Ignore warnings for desugaring library (those warnings you saw)
-dontwarn j$.util.**
-dontwarn java.lang.ClassValue
-keep class j$.util.concurrent.ConcurrentHashMap { *; }
-keep class j$.util.concurrent.ConcurrentHashMap$TreeBin { *; }
-keep class j$.util.concurrent.ConcurrentHashMap$CounterCell { *; }

# Suppress notes
-dontnote android.net.http.*
-dontnote org.apache.commons.codec.**
-dontnote org.apache.http.**