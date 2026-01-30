# ACM Monitor Mobile App

Cross-platform mobile application for the Anti-Call Masking Detection System.

## Features

- **Real-time Alert Monitoring**: View and manage fraud detection alerts
- **Push Notifications**: Instant notifications for critical alerts
- **Multi-Role Support**: Admin, Analyst, Developer, and Viewer access levels
- **Analytics Dashboard**: Visual insights into detection performance
- **Offline Support**: View cached alerts when offline

## Requirements

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode (for native builds)

## Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run in Development

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (for testing)
flutter run -d chrome
```

### 3. Build for Production

```bash
# Android APK
flutter build apk --release --flavor production

# Android App Bundle (for Play Store)
flutter build appbundle --release --flavor production

# iOS (requires macOS)
flutter build ios --release
```

## Build Scripts

Use the provided build script for automated builds:

```bash
# Make script executable
chmod +x scripts/build.sh

# Build Android only
./scripts/build.sh android

# Build iOS only (macOS only)
./scripts/build.sh ios

# Build all platforms
./scripts/build.sh all
```

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart              # App entry point
│   ├── app.dart               # App configuration & routing
│   ├── models/                # Data models
│   │   ├── alert.dart
│   │   └── user.dart
│   ├── providers/             # State management
│   │   ├── auth_provider.dart
│   │   ├── alerts_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/               # UI screens
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── alerts_screen.dart
│   │   ├── alert_detail_screen.dart
│   │   ├── analytics_screen.dart
│   │   ├── settings_screen.dart
│   │   └── profile_screen.dart
│   ├── services/              # API & business logic
│   │   ├── api_service.dart
│   │   └── notification_service.dart
│   └── theme/                 # App theming
│       └── app_theme.dart
├── android/                   # Android-specific code
├── ios/                       # iOS-specific code
└── scripts/                   # Build scripts
```

## Demo Credentials

| Role      | Email                | Password |
|-----------|---------------------|----------|
| Admin     | admin@acm.com       | demo123  |
| Analyst   | analyst@acm.com     | demo123  |
| Developer | developer@acm.com   | demo123  |
| Viewer    | viewer@acm.com      | demo123  |

## Configuration

### API URL

Update the API base URL in `lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'http://your-api-server:5001';
```

Or configure via the Settings screen in the app (Admin only).

### Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Add Android and iOS apps
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

## Build Artifacts

After building, artifacts are located at:

| Platform | Type | Location |
|----------|------|----------|
| Android | Debug APK | `build/app/outputs/flutter-apk/app-development-debug.apk` |
| Android | Release APK | `build/app/outputs/flutter-apk/app-production-release.apk` |
| Android | App Bundle | `build/app/outputs/bundle/productionRelease/app-production-release.aab` |
| iOS | Archive | `build/ios/archive/` |

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## Troubleshooting

### Android Build Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk
```

### iOS Build Issues

```bash
# Clean CocoaPods
cd ios
pod deintegrate
pod install
cd ..
flutter build ios
```

## License

Copyright 2024 ACM Monitor. All rights reserved.
