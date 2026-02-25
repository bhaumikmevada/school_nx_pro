import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  const PaymentWebViewScreen({super.key, required this.paymentUrl});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _didReturnResult = false;

  @override
  void initState() {
    super.initState();

    late PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _inspectUrl(url);
          },
          onNavigationRequest: (request) {
            final decision = _handleNavigationRequest(request.url);
            if (decision == NavigationDecision.navigate) {
              _inspectUrl(request.url);
            }
            return decision;
          },
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Online Payment")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
        ],
      ),
    );
  }

  void _inspectUrl(String url) {
    if (_didReturnResult) return;
    final normalized = url.toLowerCase();
    if (_isSuccessUrl(normalized)) {
      _completeWithResult("success");
    } else if (_isFailureUrl(normalized)) {
      _completeWithResult("failure");
    }
  }

  bool _isSuccessUrl(String url) {
    return url.contains("success") ||
        url.contains("status=success") ||
        url.contains("payment-success") ||
        url.contains("responsecode=01");
  }

  bool _isFailureUrl(String url) {
    return url.contains("failure") ||
        url.contains("failed") ||
        url.contains("status=failure") ||
        url.contains("cancel");
  }

  NavigationDecision _handleNavigationRequest(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return NavigationDecision.navigate;

    final scheme = uri.scheme.toLowerCase();
    final isHttp = scheme == "http" || scheme == "https";

    // Open UPI and other non-http schemes in an external app to avoid
    // ERR_UNKNOWN_URL_SCHEME inside the WebView.
    if (!isHttp) {
      unawaited(_launchExternal(uri));
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No app found to handle the payment link")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to open payment app: $e")),
      );
    }
  }

  void _completeWithResult(String result) {
    if (_didReturnResult || !mounted) return;
    _didReturnResult = true;
    Navigator.pop(context, result);
  }
}
