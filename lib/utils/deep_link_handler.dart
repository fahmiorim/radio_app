import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:radio_odan_app/config/app_routes.dart';

typedef DeepLinkCallback = void Function(Uri uri);

class DeepLinkHandler {
  StreamSubscription? _sub;
  DeepLinkCallback? _onDeepLink;
  GlobalKey<NavigatorState>? _navigatorKey;
  final AppLinks _appLinks = AppLinks();

  void registerHandler(
    DeepLinkCallback onDeepLink,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    _onDeepLink = onDeepLink;
    _navigatorKey = navigatorKey;
  }

  Future<void> init() async {
    try {
      debugPrint('[DeepLinkHandler] Initializing deep link handler');

      // Listen for deep links while the app is running
      _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
        debugPrint('[DeepLinkHandler] Received deep link while running: $uri');
        if (uri != null) {
          _onDeepLink?.call(uri);
        }
      }, onError: (e) => debugPrint('[DeepLinkHandler] Deep link error: \$e'));

      debugPrint('[DeepLinkHandler] Deep link handler initialized');
    } catch (e) {
      debugPrint('[DeepLinkHandler] Deep link initialization error: \$e');
    }
  }

  /// Check for initial deep link when the app is launched from a link
  Future<void> checkInitialLink() async {
    try {
      debugPrint('[DeepLinkHandler] Checking for initial deep link');
      final appLink = await _appLinks.getInitialLink();
      if (appLink != null) {
        debugPrint('[DeepLinkHandler] Found initial deep link: $appLink');
        _onDeepLink?.call(appLink);
      } else {
        debugPrint('[DeepLinkHandler] No initial deep link found');
      }
    } catch (e) {
      debugPrint('[DeepLinkHandler] Error checking initial deep link: \$e');
    }
  }

  void dispose() {
    _sub?.cancel();
    _navigatorKey = null;
    _onDeepLink = null;
  }

  void handleDeepLink(Uri? uri) async {
    debugPrint('[DeepLinkHandler] Handling deep link: $uri');
    final navigator = _navigatorKey?.currentState;
    if (uri == null || navigator == null) {
      debugPrint('[DeepLinkHandler] No URI or navigator available');
      return;
    }

    try {
      // Validasi host untuk keamanan
      final validHosts = ['odanfm.batubarakab.go.id', 'dev.odanfm.com'];
      if (!validHosts.contains(uri.host)) {
        debugPrint('[DeepLinkHandler] Host does not match: ${uri.host}');
        return;
      }

      // Menggabungkan penanganan untuk kedua format link reset password
      if (uri.path.contains('reset-password')) {
        String? token;
        String? email;

        // Coba dapatkan token dari path segments
        if (uri.pathSegments.length > 1 &&
            uri.pathSegments[0] == 'reset-password') {
          token = uri.pathSegments[1];
        }

        // Coba dapatkan token dan email dari query parameters
        token ??= uri.queryParameters['token'];
        email = uri.queryParameters['email'];

        debugPrint(
          '[DeepLinkHandler] Reset password link detected. Token: $token, Email: $email',
        );

        if (token != null && email != null) {
          final decodedEmail = Uri.decodeComponent(email);
          debugPrint('[DeepLinkHandler] Decoded email: $decodedEmail');
          _navigateToResetPassword(token, decodedEmail);
        } else {
          debugPrint('[DeepLinkHandler] Missing token or email in URL');
        }
      }
    } catch (e) {
      debugPrint('Error handling deep link: \$e');
    }
  }

  void _navigateToResetPassword(String token, String email) {
    debugPrint('[DeepLinkHandler] _navigateToResetPassword called');
    final navigator = _navigatorKey?.currentState;
    debugPrint('[DeepLinkHandler] Navigator mounted: ${navigator?.mounted}');

    if (navigator != null && navigator.mounted) {
      try {
        debugPrint(
          '[DeepLinkHandler] Navigating to reset password with token: $token, email: $email',
        );

        // Check current route
        final currentRoute = ModalRoute.of(navigator.context)?.settings.name;
        debugPrint('[DeepLinkHandler] Current route: $currentRoute');

        // Navigate to reset password screen
        debugPrint(
          '[DeepLinkHandler] Pushing reset password route: ${AppRoutes.resetPassword}',
        );

        navigator.pushNamedAndRemoveUntil(
          AppRoutes.resetPassword,
          (route) => false, // Remove all routes below
          arguments: {'token': token, 'email': email},
        );

        debugPrint('[DeepLinkHandler] Navigation completed');
      } catch (e, stackTrace) {
        debugPrint('[DeepLinkHandler] Navigation error: $e');
        debugPrint(stackTrace.toString());
      }
    } else {
      debugPrint('[DeepLinkHandler] Navigator not mounted, cannot navigate');
    }
  }
}
