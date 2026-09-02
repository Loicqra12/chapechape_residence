import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import '../models/stay_credential_preview.dart';

String _safeDiagnostic(Object? value) =>
    redactStayCredentials(value.toString());

/// Observateur de Bloc personnalisé pour surveiller les événements, 
/// transitions et erreurs dans tous les blocs de l'application partenaire
class AppBlocObserver extends BlocObserver {
  final _logger = Logger('BlocObserver');

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _logger.fine('📌 onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.info('📩 onEvent -- ${bloc.runtimeType}, event: ${_safeDiagnostic(event)}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _logger.fine('🔄 onChange -- ${bloc.runtimeType}, change: ${_safeDiagnostic(change)}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _logger.info(
      '⏩ onTransition -- ${bloc.runtimeType}, transition: ${_safeDiagnostic(transition)}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.severe('❌ onError -- ${bloc.runtimeType}', error, stackTrace);
    
    final errorMessage = _safeDiagnostic(error);
    
    _logger.severe(
      '❌ Erreur dans bloc ${bloc.runtimeType}: $errorMessage',
      error,
      stackTrace,
    );
    
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _logger.fine('🚫 onClose -- ${bloc.runtimeType}');
  }
}
