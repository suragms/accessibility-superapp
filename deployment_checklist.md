# Production Deployment Checklist - Accessibility Super App

Use this step-by-step checklist to prepare, build, sign, and distribute production-grade releases of the Accessibility Super App to Google Play Console and Apple App Store Connect.

---

## 1. Android Release & Google Play Store Setup

### A. Signing Keystore Generation
To securely sign the release application bundle (AAB) for distribution:
1. Run the following command to generate a upload keystore file:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create a secure local file `android/key.properties` (never commit this file to git):
   ```properties
   storePassword=your-keystore-password
   keyPassword=your-key-password
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. Update `android/app/build.gradle` to automatically load `key.properties` and sign release configurations:
   ```groovy
   def keystorePropertiesFile = rootProject.file('key.properties')
   // Load property configurations into signingConfigs.release
   ```

### B. Google Play Console API Access
To enable Fastlane automated uploads to the Internal Test Track:
1. Open the Google Play Console -> **Setup** -> **API Access**.
2. Create/Link a Google Cloud Project and create a **Service Account** with **Release Manager** permissions.
3. Generate a service account credentials JSON key file, rename it to `play_store_api_key.json`, and place it in the `android/` directory.

---

## 2. iOS Release & Apple App Store Setup

### A. Code Signing Certificates (via Fastlane Match)
Instead of manually managing certificates, utilize Fastlane Match:
1. Create a private git repository to store encrypted certificates (e.g., `git@github.com:yourorg/app-certificates.git`).
2. Run `fastlane match init` to configure the Match storage repo.
3. Run `fastlane match appstore` to generate and sync production certificates and provisioning profiles.

### B. App Store Connect Application
1. Log into App Store Connect -> **My Apps** -> **Create New App**.
2. Enter app details: name, bundle ID (`com.accessibility.superapp`), language, and SKU.
3. In Xcode, ensure the Bundle Identifier matches the bundle ID, and select the Match provisioning profile.

---

## 3. Firebase Console Setup (Telemetry, Telemetric Syncs)

### A. Firebase App Registration
1. Go to the Firebase Console -> **Create Project**.
2. Register the Android App Bundle ID: `com.accessibility.superapp`
   - Download the generated `google-services.json` and place it in `android/app/`.
3. Register the iOS Bundle ID: `com.accessibility.superapp`
   - Download the generated `GoogleService-Info.plist` and place it in `ios/Runner/`.

### B. Firebase Crashlytics & Performance SDK
1. In `pubspec.yaml`, add the dependency versions:
   ```yaml
   firebase_core: ^3.0.0
   firebase_crashlytics: ^4.0.0
   firebase_performance: ^4.0.0
   ```
2. Android Setup:
   - Apply the google-services and crashlytics plugins in `android/build.gradle` and `android/app/build.gradle`.
3. iOS Setup:
   - Ensure CocoaPods links the static framework references.
4. App Initialization (`lib/main.dart`):
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp();
   // Pass uncaught errors directly to Crashlytics
   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
   ```

---

## 4. Automation & Deployment Lane Commands

Automate the compile, sign, and upload steps using these terminal commands:

### Android Release
- **Internal Test Track Distribution**:
  ```bash
  cd android
  bundle exec fastlane upload_internal
  ```

### iOS Release
- **TestFlight Beta Distribution**:
  ```bash
  cd ios
  bundle exec fastlane upload_testflight
  ```
