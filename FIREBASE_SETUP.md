# Firebase Setup Guide for KSK Finance App

## Steps to integrate Firebase:

### 1. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Add Android app with package name: `com.sasiksk.kskfinance`
4. Download `google-services.json` and place in `android/app/`
5. Add iOS app with bundle ID: `com.sasiksk.kskfinance`
6. Download `GoogleService-Info.plist` and place in `ios/Runner/`

### 2. Enable Firestore Database
1. In Firebase Console, go to Firestore Database
2. Create database in production mode
3. Set security rules (example):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{document} {
      allow read, write: if true; // Adjust security as needed
    }
  }
}
```

### 3. Android Configuration
Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.2.2')
    implementation 'com.google.firebase:firebase-firestore'
}
```

Add to `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

### 4. iOS Configuration
1. Add `GoogleService-Info.plist` to `ios/Runner/` in Xcode
2. Update `ios/Runner/Info.plist` if needed

### 5. Main.dart Initialization
Uncomment and add Firebase initialization:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Uncomment this line
  // ... rest of main function
}
```

### 6. Enable Firebase in OnboardingScreen
In `lib/Screens/Main/OnboardingScreen.dart`:
1. Uncomment the Firebase import
2. Uncomment the FirebaseFirestore instance
3. Uncomment the Firebase registration code in `_registerUser()` method

### 7. Data Structure
The app will save user data to Firestore with this structure:
```json
{
  "name": "User Name",
  "phone": "1234567890", 
  "registeredAt": "timestamp",
  "appVersion": "1.0.0"
}
```

### 8. Test Firebase Integration
Run the app and complete registration to test Firebase connectivity.

## Current Status
- ✅ Dependencies added to pubspec.yaml
- ✅ Firebase code prepared (commented out)
- ❌ Firebase project setup (needs manual configuration)
- ❌ google-services.json file (needs download from Firebase Console)
- ❌ Firebase initialization (commented out in main.dart)

## Security Considerations
- Implement proper Firestore security rules
- Consider user authentication if needed
- Validate phone numbers server-side
- Implement data backup and recovery