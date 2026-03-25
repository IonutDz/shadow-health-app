# shadow-health-app

ShadowHealth Flutter app — iOS, Android & Web.

## Stack
- **Framework:** Flutter (Dart)
- **State management:** Riverpod
- **API client:** Dio
- **Local storage:** Hive / SharedPreferences

## Structure
```
lib/
├── features/          # Feature modules
│   ├── auth/
│   ├── dashboard/
│   ├── workout/
│   ├── nutrition/
│   ├── body/
│   ├── sleep/
│   ├── health/
│   └── settings/
├── core/
│   ├── api/           # API client, interceptors
│   ├── models/        # Data models
│   ├── utils/         # Helpers
│   └── theme/         # App theme
└── shared/
    ├── widgets/       # Reusable widgets
    └── constants/     # App constants
assets/
├── images/
├── fonts/
└── icons/
```

## Setup
```bash
flutter pub get
flutter run
```

## Platforms
- ✅ Android
- ✅ iOS
- ✅ Web (Flutter Web)
