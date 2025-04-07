import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget standardisé pour afficher les erreurs dans l'application
class ErrorDisplay extends StatelessWidget {
  /// Message d'erreur principal à afficher à l'utilisateur
  final String message;
  
  /// Détails techniques supplémentaires (affichés uniquement en mode debug)
  final String? technicalDetails;
  
  /// Indique si l'erreur est liée à un problème de réseau
  final bool isNetworkError;
  
  /// Indique si l'erreur est liée à l'authentification (session expirée, etc.)
  final bool isAuthError;
  
  /// Fonction à appeler lorsque l'utilisateur appuie sur le bouton "Réessayer"
  final VoidCallback? onRetry;
  
  /// Fonction à appeler lorsque l'utilisateur appuie sur le bouton "Support"
  final VoidCallback? onSupportRequest;
  
  const ErrorDisplay({
    Key? key,
    required this.message,
    this.technicalDetails,
    this.isNetworkError = false,
    this.isAuthError = false,
    this.onRetry,
    this.onSupportRequest,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône appropriée selon le type d'erreur
            Icon(
              isNetworkError 
                ? Icons.wifi_off
                : isAuthError 
                  ? Icons.lock_outline
                  : Icons.error_outline,
              size: 60,
              color: isNetworkError 
                ? Colors.orange 
                : isAuthError 
                  ? Theme.of(context).colorScheme.error 
                  : Colors.red,
            ),
            const SizedBox(height: 20),
            
            // Message principal d'erreur
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Détails techniques (uniquement en mode debug)
            if (technicalDetails != null && kDebugMode) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  technicalDetails!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Bouton de reconnexion pour erreurs d'authentification
            if (isAuthError) ...[
              ElevatedButton.icon(
                onPressed: () => context.go('/auth/login'),
                icon: const Icon(Icons.login),
                label: const Text('Se reconnecter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 45),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Bouton réessayer
            if (onRetry != null) ...[
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 45),
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Bouton support
            if (onSupportRequest != null) ...[
              OutlinedButton.icon(
                onPressed: onSupportRequest,
                icon: const Icon(Icons.support_agent),
                label: const Text('Contacter le support'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 