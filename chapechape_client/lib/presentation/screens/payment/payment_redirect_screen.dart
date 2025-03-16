import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/config/theme.dart';

class PaymentRedirectScreen extends StatefulWidget {
  final String paymentId;

  const PaymentRedirectScreen({
    Key? key,
    required this.paymentId,
  }) : super(key: key);

  @override
  State<PaymentRedirectScreen> createState() => _PaymentRedirectScreenState();
}

class _PaymentRedirectScreenState extends State<PaymentRedirectScreen> {
  bool _isLoading = true;
  String? _redirectUrl;
  late WebViewController _webViewController;
  bool _checkingStatus = false;
  
  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
    
    // Initialiser le contrôleur WebView avec la nouvelle API
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Vérifier si l'URL correspond à une URL de retour après paiement réussi ou échoué
            if (url.contains('payment_success') || 
                url.contains('success') || 
                url.contains('return')) {
              _checkPaymentStatus();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercepter certaines navigations si nécessaire
            return NavigationDecision.navigate;
          },
        ),
      );
    
    // Vérifier périodiquement le statut du paiement
    Future.delayed(const Duration(seconds: 10), _startPeriodicStatusCheck);
  }
  
  void _loadPaymentDetails() {
    context.read<PaymentBloc>().add(
      CheckPaymentStatus(paymentId: widget.paymentId),
    );
  }
  
  void _startPeriodicStatusCheck() {
    if (!mounted) return;
    
    setState(() {
      _checkingStatus = true;
    });
    
    // Vérifier le statut toutes les 10 secondes
    Future.delayed(const Duration(seconds: 10), () {
      _checkPaymentStatus();
      
      if (mounted && _checkingStatus) {
        _startPeriodicStatusCheck();
      }
    });
  }
  
  void _checkPaymentStatus() {
    context.read<PaymentBloc>().add(
      CheckPaymentStatus(paymentId: widget.paymentId),
    );
  }
  
  Future<bool?> _showExitConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Êtes-vous sûr ?'),
        content: const Text(
          'Si vous quittez maintenant, votre paiement pourrait être interrompu. '
          'Êtes-vous sûr de vouloir quitter ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('QUITTER'),
          ),
        ],
      ),
    );
  }
  
  void _onBackPressed(BuildContext context) async {
    final confirm = await _showExitConfirmDialog();
    if (confirm == true) {
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmDialog() ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paiement en cours'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkPaymentStatus,
              tooltip: 'Actualiser le statut',
            ),
          ],
        ),
        body: BlocConsumer<PaymentBloc, PaymentState>(
          listener: (context, state) {
            if (state is PaymentLoading) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is PaymentStatusChecked) {
              setState(() {
                _isLoading = false;
              });
              
              // Si le paiement est réussi, naviguer vers l'écran de succès
              if (state.payment.status == PaymentStatus.succeeded) {
                context.go('/payment/success/${widget.paymentId}');
              }
              
              // Mettre à jour l'URL de redirection si disponible
              final redirectUrl = state.payment.metadata?['redirectUrl'] as String?;
              if (redirectUrl != null && redirectUrl.isNotEmpty) {
                setState(() {
                  _redirectUrl = redirectUrl;
                });
                
                // Charger l'URL dans la WebView
                if (_redirectUrl != null) {
                  _webViewController.loadRequest(Uri.parse(_redirectUrl!));
                }
              }
            } else if (state is PaymentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              setState(() {
                _isLoading = false;
              });
            }
          },
          builder: (context, state) {
            return _buildContent();
          },
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_redirectUrl == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Préparation de la page de paiement...'),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Barre de progression en haut
        if (_checkingStatus)
          const LinearProgressIndicator(),
          
        // Bannière d'information
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.secondaryColor.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paiement en cours',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Veuillez suivre les instructions sur la page de paiement.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ne fermez pas cette page jusqu\'à ce que le paiement soit terminé.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // WebView
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _checkingStatus = false;
    super.dispose();
  }
} 