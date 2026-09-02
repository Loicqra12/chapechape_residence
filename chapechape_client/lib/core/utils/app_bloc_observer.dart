import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api/interceptors/logging_interceptor.dart';
import 'global_error_handler.dart';
import 'logger.dart';

String _safeDiagnostic(Object? value) =>
    redactStayCredentials(value.toString());

/// Observateur de Bloc personnalisé pour surveiller les événements, 
/// transitions et erreurs dans tous les blocs de l'application
class AppBlocObserver extends BlocObserver {
  final _logger = AppLogger('AppBlocObserver');
  final _errorHandler = GlobalErrorHandler();

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.debug('onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.debug('onEvent -- ${bloc.runtimeType}, event: ${_safeDiagnostic(event)}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.debug('onChange -- ${bloc.runtimeType}, change: ${_safeDiagnostic(change)}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.debug(
      'onTransition -- ${bloc.runtimeType}, transition: ${_safeDiagnostic(transition)}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.error('onError -- ${bloc.runtimeType}', error, stackTrace);
    
    // Utiliser le gestionnaire d'erreurs global pour traiter l'erreur
    final errorMessage = _safeDiagnostic(_errorHandler.handleError(error));
    _logger.error(
      'Erreur dans bloc ${bloc.runtimeType}: $errorMessage',
      error,
      stackTrace,
    );
    
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.debug('onClose -- ${bloc.runtimeType}');
  }
} 