// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import '../cef_webview.dart';
import 'webview_cef.dart';
import 'webview_cef_widget.dart';

/// Cef [WebViewPlatform] that uses [CefViewSurface] to build the
/// [WebView] widget.
///
/// To use this, set [WebView.platform] to an instance of this class.
///
/// This implementation uses [CefViewSurface] to render the [WebView] on
/// Cef. It solves multiple issues related to accessibility and interaction
/// with the [WebView] at the cost of some performance on Cef versions below
/// 10.
///
/// To support transparent backgrounds on all Cef devices, this
/// implementation uses hybrid composition when the opacity of
/// `CreationParams.backgroundColor` is less than 1.0. See
/// https://github.com/flutter/flutter/wiki/Hybrid-Composition for more
/// information.
class SurfaceCefWebView extends CefWebView {
  /// Constructs a [SurfaceCefWebView].
  SurfaceCefWebView({@visibleForTesting super.instanceManager});

  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required JavascriptChannelRegistry javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
  }) {
    return WebViewCefWidget(
      creationParams: creationParams,
      callbacksHandler: webViewPlatformCallbacksHandler,
      javascriptChannelRegistry: javascriptChannelRegistry,
      onBuildWidget: (WebViewCefPlatformController controller) {
        return PlatformViewLink(
          viewType: 'plugins.flutter.io/webview',
          surfaceFactory: (
            BuildContext context,
            PlatformViewController controller,
          ) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: gestureRecognizers ??
                  const <Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            final Color? backgroundColor = creationParams.backgroundColor;
            return _createViewController(
              // On some Cef devices, transparent backgrounds can cause
              // rendering issues on the non hybrid composition
              // CefViewSurface. This switches the WebView to Hybrid
              // Composition when the background color is not 100% opaque.
              hybridComposition:
                  backgroundColor != null && backgroundColor.opacity < 1.0,
              id: params.id,
              viewType: 'plugins.flutter.io/webview',
              // WebView content is not affected by the Cef view's layout direction,
              // we explicitly set it here so that the widget doesn't require an ambient
              // directionality.
              layoutDirection:
                  Directionality.maybeOf(context) ?? TextDirection.ltr,
              webViewIdentifier:
                  instanceManager.getIdentifier(controller.webView)!,
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener((int id) {
                if (onWebViewPlatformCreated != null) {
                  onWebViewPlatformCreated(controller);
                }
              })
              ..create();
          },
        );
      },
    );
  }

  AndroidViewController _createViewController({
    required bool hybridComposition,
    required int id,
    required String viewType,
    required TextDirection layoutDirection,
    required int webViewIdentifier,
  }) {
    if (hybridComposition) {
      return PlatformViewsService.initExpensiveAndroidView(
        id: id,
        viewType: viewType,
        layoutDirection: layoutDirection,
        creationParams: webViewIdentifier,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return PlatformViewsService.initSurfaceAndroidView(
      id: id,
      viewType: viewType,
      layoutDirection: layoutDirection,
      creationParams: webViewIdentifier,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
