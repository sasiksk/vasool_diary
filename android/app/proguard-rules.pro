# Add project specific ProGuard rules here.

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep SQLite classes for your database
-keep class ** extends androidx.sqlite.db.SupportSQLiteOpenHelper { *; }

# Keep your custom classes
-keep class com.DigiThinkers.VasoolDiary.** { *; }

# 16KB memory page size compatibility
-dontwarn com.google.android.gms.**
-dontwarn androidx.**

# Keep Firebase classes if using
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**