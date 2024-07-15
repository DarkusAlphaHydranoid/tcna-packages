// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import '../cef_webview.dart' as cef_webview;

/// Handles all cookie operations for the current platform.
class WebViewCefCookieManager extends WebViewCookieManagerPlatform {
  /// Constructs a [WebViewCefCookieManager].
  WebViewCefCookieManager({
    @visibleForTesting cef_webview.CookieManager? cookieManager,
  }) : _cookieManager = cookieManager ?? cef_webview.CookieManager.instance;

  final cef_webview.CookieManager _cookieManager;

  @override
  Future<bool> clearCookies() => _cookieManager.removeAllCookies();

  @override
  Future<void> setCookie(WebViewCookie cookie) {
    if (!_isValidPath(cookie.path)) {
      throw ArgumentError(
          'The path property for the provided cookie was not given a legal value.');
    }
    return _cookieManager.setCookie(
      cookie.domain,
      '${Uri.encodeComponent(cookie.name)}=${Uri.encodeComponent(cookie.value)}; path=${cookie.path}',
    );
  }

  bool _isValidPath(String path) {
    // Permitted ranges based on RFC6265bis: https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-02#section-4.1.1
    for (final int char in path.codeUnits) {
      if ((char < 0x20 || char > 0x3A) && (char < 0x3C || char > 0x7E)) {
        return false;
      }
    }
    return true;
  }
}
