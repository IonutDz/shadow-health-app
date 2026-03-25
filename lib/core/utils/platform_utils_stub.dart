/// Stub implementation for non-web platforms (Android APK, iOS, desktop).
/// On native Android the user already HAS the app, so never redirect.

/// URL where the release APK is hosted.
const String kApkDownloadUrl =
    'https://github.com/shadow-health/shadow-health-app/releases/latest/download/shadow-health.apk';

/// Public web URL of this Flutter web app (used for QR code).
const String kWebAppUrl = 'https://shadow-health.web.app';

/// Always false on native — the user is already running the native app.
bool get isWebOnAndroid => false;

/// Raw user-agent string (empty on native).
String get userAgent => '';
