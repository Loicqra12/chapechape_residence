import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../models/partner/partner_model.dart';
import '../../services/api/auth_service.dart';
import '../../services/api/media_service.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../exceptions/api_exception.dart';
import '../../services/onesignal_service.dart';
import 'auth_event.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

// Note: Les événements sont maintenant définis dans auth_event.dart

// État d'authentification
class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final String? userId;
  
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
  });
  
  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userId: userId ?? this.userId,
    );
  }
  
  @override
  List<Object?> get props => [isAuthenticated, isLoading, errorMessage, userId];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final Partner partner;

  const AuthAuthenticated({
    required this.token,
    required this.partner,
  });

  @override
  List<Object?> get props => [token, partner];

  @override
  String toString() {
    final masked = token.length <= 12
        ? '***'
        : '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
    return 'AuthAuthenticated($masked, $partner)';
  }
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc d'authentification
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final MediaService _mediaService;
  final FlutterSecureStorage storage;

  AuthBloc({
    required AuthService authService,
    required this.storage,
    MediaService? mediaService,
  })  : _authService = authService,
        _mediaService = mediaService ?? MediaService(Dio()),
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<UploadProfilePictureRequested>(_onUploadProfilePictureRequested);
    on<UploadDocumentRequested>(_onUploadDocumentRequested);
    on<AuthDeleteAccountRequested>(_onDeleteAccount);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);

    // Vérifier l'état d'authentification au démarrage
    add(AuthCheckRequested());
  }

  Future<void> _syncPushForPartner(String partnerId) async {
    try {
      await OneSignalService().syncAfterLogin(partnerId);
    } catch (_) {}
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await storage.read(key: 'token');
      if (token != null) {
        // Nettoyage one-shot : ancien JWT éventuellement stocké en clair
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
        } catch (_) {}

        final partner = await _authService.getProfile();
        
        // Stocker l'ID du partenaire pour filtrer les résidences
        await storage.write(key: 'userId', value: partner.id);
        AppLogger.d("ID partenaire stocké lors de la vérification: ${partner.id}");
        
        // Stocker le rôle du partenaire
        await storage.write(key: 'userRole', value: 'partner');
        AppLogger.d("Rôle partenaire stocké lors de la vérification: partner");
        
        // Sauvegarder les données du partenaire pour persistance après hot reload
        // Mais seulement si on a des données valides
        if (partner.profilePictureUrl != null && 
            partner.profilePictureUrl!.isNotEmpty && 
            partner.profilePictureUrl != "" &&
            partner.profilePictureUrl!.startsWith('http')) {
          await storage.write(key: 'partner_data', value: jsonEncode(partner.toJson()));
          AppLogger.d("✅ Données partenaire sauvegardées avec photo valide: ${partner.profilePictureUrl}");
        } else {
          AppLogger.d("⚠️ Photo de profil invalide détectée, sauvegarde sélective sans écraser le cache existant");
        }
        
        emit(AuthAuthenticated(token: token, partner: partner));
        await _syncPushForPartner(partner.id);
      } else {
        // Nettoyage legacy SharedPreferences (JWT ne doit plus y vivre)
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
        } catch (_) {}
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final loginResult = await _authService.login(
        email: event.email,
        password: event.password,
      );
      
      // Stocker les tokens
      await storage.write(key: 'token', value: loginResult.token);
      
      // Stocker le refresh token
      if (loginResult.refreshToken != null) {
        await storage.write(key: 'refresh_token', value: loginResult.refreshToken);
        
        // Calculer et stocker la date d'expiration (90 jours pour rester connecté longtemps)
        final expiryDate = DateTime.now().add(Duration(days: 90));
        await storage.write(key: 'token_expiry', value: expiryDate.toIso8601String());
        AppLogger.d('📝 Token et refresh token stockés (expire le ${expiryDate.toLocal()})');
      }
      
      // Utiliser l'ID réel du partenaire depuis la réponse backend
      String partnerId = loginResult.partner.id;
      
      AppLogger.d("ID du partenaire authentifié: $partnerId");
      
      // Stocker l'ID du partenaire pour filtrer les résidences
      await storage.write(key: 'userId', value: partnerId);
      AppLogger.d("ID partenaire stocké: $partnerId");
      
      // Stocker le rôle réel du partenaire (peut être partner_pending)
      await storage.write(key: 'userRole', value: loginResult.partner.role);
      AppLogger.d("Rôle partenaire stocké: ${loginResult.partner.role}");
      
      // Vérifier que l'ID a bien été enregistré
      final storedId = await storage.read(key: 'userId');
      AppLogger.d("ID partenaire lu depuis le storage: $storedId");
      
      emit(AuthAuthenticated(
        token: loginResult.token,
        partner: loginResult.partner,
      ));
      await _syncPushForPartner(loginResult.partner.id);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Un problème est survenu. Réessayez.';
      emit(AuthFailure(message));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final registerResult = await _authService.register(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        countryCode: event.countryCode,
      );
      
      // Stocker les tokens
      await storage.write(key: 'token', value: registerResult.token);
      
      // Stocker le refresh token
      if (registerResult.refreshToken != null) {
        await storage.write(key: 'refresh_token', value: registerResult.refreshToken);
        
        // Calculer et stocker la date d'expiration (90 jours pour rester connecté longtemps)
        final expiryDate = DateTime.now().add(Duration(days: 90));
        await storage.write(key: 'token_expiry', value: expiryDate.toIso8601String());
        AppLogger.d('📝 Token et refresh token stockés (expire le ${expiryDate.toLocal()})');
      }
      
      // Stocker l'ID du partenaire pour filtrer les résidences
      await storage.write(key: 'userId', value: registerResult.partner.id);
      AppLogger.d("ID partenaire stocké: ${registerResult.partner.id}");
      
      // Stocker le rôle réel du partenaire (peut être partner_pending après inscription)
      await storage.write(key: 'userRole', value: registerResult.partner.role);
      AppLogger.d("Rôle partenaire stocké: ${registerResult.partner.role}");
      
      emit(AuthAuthenticated(
        token: registerResult.token,
        partner: registerResult.partner,
      ));
      await _syncPushForPartner(registerResult.partner.id);
    } catch (e) {
      final message = e is ApiException ? e.message : 'Un problème est survenu. Réessayez.';
      emit(AuthFailure(message));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Unregister device AVANT purge du JWT
      try {
        await OneSignalService().onLogout();
      } catch (_) {}
      await storage.delete(key: 'token');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'token_expiry');
      await storage.delete(key: 'userId');
      await storage.delete(key: 'userRole');
      await storage.delete(key: 'partner_data'); // Supprimer le cache des données partenaire
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
      } catch (_) {}
      AppLogger.d("🧹 Cache des données partenaire effacé lors de la déconnexion");
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(AuthLoading());
        
        final partner = await _authService.updateProfile(event.userData);
        
        emit(AuthAuthenticated(
          token: currentState.token,
          partner: partner,
        ));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onUploadProfilePictureRequested(
    UploadProfilePictureRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(AuthLoading());
        
        final imageUrl = await _mediaService.uploadProfilePicture(event.imageFile);
        AppLogger.d('Mise à jour du profil avec les données: {profilePictureUrl: $imageUrl}');
        
        // Au lieu de mettre à jour le profil localement,
        // récupérer le profil complet depuis le serveur
        final updatedPartner = await _authService.getProfile();
        
        AppLogger.d('Profil récupéré après upload: ${updatedPartner.profilePictureUrl}');
        
        // Sauvegarder les nouvelles données du partenaire avec la photo mise à jour
        await storage.write(key: 'partner_data', value: jsonEncode(updatedPartner.toJson()));
        AppLogger.d('Nouvelles données partenaire sauvegardées après upload photo: ${updatedPartner.profilePictureUrl}');
        
        emit(AuthAuthenticated(
          token: currentState.token,
          partner: updatedPartner,
        ));
        
        AppLogger.d('Profil mis à jour avec succès');
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onUploadDocumentRequested(
    UploadDocumentRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (state is AuthAuthenticated) {
        final currentState = state as AuthAuthenticated;
        emit(AuthLoading());
        
        final fileOrBytes = event.documentFile ?? event.documentBytes;
        final documentUrl = await _mediaService.uploadDocument(
          event.documentType,
          fileOrBytes,
        );
        
        // Après l'upload, récupérer les données mises à jour du partenaire
        final updatedPartner = await _authService.getProfile();
        
        emit(AuthAuthenticated(
          token: currentState.token,
          partner: updatedPartner,
        ));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onDeleteAccount(AuthDeleteAccountRequested event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      try {
        // Désenregistrer le device tant que le JWT est encore valide
        try {
          await OneSignalService().onLogout();
        } catch (_) {}

        final success = await _authService.deleteAccount(event.password);
        
        if (success) {
          // Le nettoyage du stockage est déjà géré dans la méthode deleteAccount
          emit(AuthUnauthenticated());
        } else {
          emit(state.copyWith(
            isLoading: false,
            errorMessage: 'La suppression du compte a échoué. Veuillez réessayer.',
          ));
        }
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Erreur: ${e.toString()}',
        ));
      }
    }
  }
  
  // Gérer l'événement de demande de réinitialisation de mot de passe
  Future<void> _onForgotPasswordRequested(ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final success = await _authService.requestPasswordReset(event.email);
      
      if (success) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'La demande de réinitialisation a échoué. Vérifiez votre email.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur: ${e.toString()}',
      ));
    }
  }
  
  // Gérer l'événement de réinitialisation de mot de passe
  Future<void> _onResetPasswordRequested(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final success = await _authService.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
      );
      
      if (success) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'La réinitialisation du mot de passe a échoué. Vérifiez le token.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur: ${e.toString()}',
      ));
    }
  }
}
