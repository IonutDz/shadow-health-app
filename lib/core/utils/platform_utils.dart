/// Cross-platform utilities for platform/user-agent detection.
/// Uses conditional exports: `platform_utils_stub.dart` for native,
/// `platform_utils_web.dart` for web.
export 'platform_utils_stub.dart'
    if (dart.library.html) 'platform_utils_web.dart';
