import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Hide the website header/navigation/footer for a cleaner content-only view
            _controller.runJavaScript('''
              // Hide header navigation
              var header = document.querySelector('header');
              if (header) header.style.display = 'none';

              // Hide navigation bar
              var nav = document.querySelector('nav');
              if (nav) nav.style.display = 'none';

              // Hide footer
              var footer = document.querySelector('footer');
              if (footer) footer.style.display = 'none';

              // Hide any element with class containing 'header', 'nav', or 'footer'
              var elements = document.querySelectorAll('[class*="header"], [class*="Header"], [class*="nav"], [class*="Nav"], [class*="footer"], [class*="Footer"]');
              elements.forEach(function(el) {
                if (el.tagName !== 'MAIN' && el.tagName !== 'ARTICLE') {
                  el.style.display = 'none';
                }
              });

              // Adjust body padding/margin to remove gaps
              document.body.style.paddingTop = '0';
              document.body.style.marginTop = '0';
              document.body.style.paddingBottom = '0';
              document.body.style.marginBottom = '0';
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load page: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppConstants.fontSize18,
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _controller.reload();
            },
            icon: Icon(
              Icons.refresh,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Refresh',
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
