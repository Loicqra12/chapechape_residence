import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/utils/global_error_handler.dart';

/// Widget réutilisable pour gérer les erreurs dans l'application
/// Entoure un widget enfant et gère les erreurs de Bloc de manière élégante
class ErrorHandlerWidget<B extends StateStreamable<S>, S> extends StatelessWidget {
  final Widget child;
  final BlocWidgetListener<S> listener;
  final bool Function(S state) hasError;
  final String Function(S state) errorMessage;
  final VoidCallback? onRetry;
  final bool showDialog;

  const ErrorHandlerWidget({
    Key? key,
    required this.child,
    required this.listener,
    required this.hasError,
    required this.errorMessage,
    this.onRetry,
    this.showDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listener: (context, state) {
        if (hasError(state)) {
          final message = errorMessage(state);
          if (showDialog) {
            GlobalErrorHandler().showErrorDialog(context, message);
          } else {
            GlobalErrorHandler().showErrorSnackBar(context, message);
          }
          
          listener(context, state);
        }
      },
      child: child,
    );
  }
}

/// Extension qui facilite l'utilisation du widget d'erreur avec des blocs
extension ErrorHandlingExtension on BuildContext {
  /// Affiche un message d'erreur dans un snackbar
  void showErrorSnackBar(String message) {
    GlobalErrorHandler().showErrorSnackBar(this, message);
  }
  
  /// Affiche un message d'erreur dans une boîte de dialogue
  void showErrorDialog(String message) {
    GlobalErrorHandler().showErrorDialog(this, message);
  }
  
  /// Traite une erreur et affiche un message approprié
  String handleError(dynamic error) {
    return GlobalErrorHandler().handleError(error);
  }
} 