import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String transactionId;
  final String paymentMethod;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.transactionId,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _handleUrlChange(url);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Erreur de connexion. Vérifiez votre internet.';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleUrlChange(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _handleUrlChange(String url) {
    // Détecter les URLs de succès/échec CinetPay
    if (url.contains('/payment/success') || url.contains('success')) {
      _navigateToSuccess();
    } else if (url.contains('/payment/cancel') ||
        url.contains('/payment/failed') ||
        url.contains('cancel') ||
        url.contains('failed')) {
      _navigateToFailure();
    }
  }

  void _navigateToSuccess() {
    context.pushReplacement('/payment-success', extra: {
      'transactionId': widget.transactionId,
      'paymentMethod': widget.paymentMethod,
    });
  }

  void _navigateToFailure() {
    context.pushReplacement('/payment-failed', extra: {
      'transactionId': widget.transactionId,
      'paymentMethod': widget.paymentMethod,
      'error': 'Paiement annulé ou échoué',
    });
  }

  String _getPaymentMethodTitle() {
    switch (widget.paymentMethod) {
      case 'om':
        return 'Orange Money';
      case 'mtn_money':
        return 'MTN Money';
      case 'momo':
        return 'Moov Money';
      case 'credit_card':
        return 'Carte bancaire';
      default:
        return 'Paiement sécurisé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPaymentMethodTitle()),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          if (_errorMessage == null)
            WebViewWidget(controller: _controller)
          else
            _buildErrorWidget(),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement du paiement sécurisé...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vous allez être redirigé vers ${_getPaymentMethodTitle()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _controller.reload(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelDialog() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le paiement'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ce paiement ? '
          'Vous devrez recommencer la procédure.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      context.pop();
    }
  }
}
