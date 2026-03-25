// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// URL where the release APK is hosted.
const String kApkDownloadUrl =
    'https://github.com/shadow-health/shadow-health-app/releases/latest/download/shadow-health.apk';

/// Public web URL of this Flutter web app (used for QR code).
const String kWebAppUrl = 'https://shadow-health.web.app';

/// Raw navigator.userAgent from the browser.
String get userAgent => html.window.navigator.userAgent;

/// True when running in a browser on Android.
bool get isWebOnAndroid =>
    html.window.navigator.userAgent.toLowerCase().contains('android');
