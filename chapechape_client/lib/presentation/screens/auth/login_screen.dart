import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chapechape_client/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_event.dart';
import 'package:chapechape_client/core/blocs/auth/auth_state.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/constants/app_assets.dart';
import 'package:chapechape_client/core/utils/form_validators.dart';
import 'package:chapechape_client/core/services/error_message_service.dart';
import 'package:chapechape_client/presentation/widgets/custom_button.dart';
import 'package:chapechape_client/presentation/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  String _email = '';
  String _password = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        context.read<AuthBloc>().add(
              LoginRequested(
                email: _email,
                password: _password,
                rememberMe: _rememberMe,
              ),
            );
        // Le BlocConsumer s'occupera de la navigation en cas de succès
      } catch (e) {
        ErrorMessageService.showError(
          context,
          e,
          contextType: 'login',
          onRetry: _submitForm,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
          ErrorMessageService.showSuccess(
            context,
            'Connexion réussie !',
          );
        } else if (state is AuthError) {
          ErrorMessageService.showError(
            context,
            state.message,
            contextType: 'login',
            onRetry: _submitForm,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const SizedBox.shrink(),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/home'),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Illustration : compacte, tout visible + fondu
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          const maxH = 130.0;
                          return SizedBox(
                            height: maxH + 20,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox(
                                  width: maxW,
                                  height: maxH,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Image.asset(
                                      'assets/images/empty_states/empty_connexion_illustration.png',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 36,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bienvenue sur ChapeChape',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalSm,
                      Text(
                        'Connectez-vous pour accéder à votre compte',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email ou téléphone',
                        hintText: 'Entrez votre email ou numéro de téléphone',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.validateEmailOrPhone,
                        onSaved: (value) => _email = value ?? '',
                      ),
                      AppSpacing.verticalSmd,
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Mot de passe',
                        hintText: 'Entrez votre mot de passe',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        validator: FormValidators.validatePassword,
                        onSaved: (value) => _password = value ?? '',
                      ),
                      AppSpacing.verticalSmd,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primaryColor,
                                  ),
                                ),
                                AppSpacing.horizontalSm,
                                Flexible(
                                  child: Text(
                                    'Se souvenir de moi',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: TextButton(
                              onPressed: () {
                                // Naviguer vers la page de récupération de mot de passe
                                context.go('/forgot-password');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                minimumSize: const Size(0, 36),
                              ),
                              child: Text(
                                'Mot de passe oublié?',
                                style: AppTextStyles.link,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSmd,
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: state is AuthLoading ? 'Connexion en cours...' : 'Se connecter',
                          isLoading: state is AuthLoading,
                          onPressed: state is AuthLoading ? null : _submitForm,
                        ),
                      ),
                      AppSpacing.verticalSmd,
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Vous n\'avez pas de compte?',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              'S\'inscrire',
                              style: AppTextStyles.link,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSmd,
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text(
                              'Ou connectez-vous avec',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSmd,
                      Center(
                        child: _googleLoginButton(
                          onPressed: () {
                            context.read<AuthBloc>().add(
                                  const GoogleLoginRequested(),
                                );
                          },
                        ),
                      ),
                      AppSpacing.verticalSmd,
                      // Message légal
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text.rich(
                          TextSpan(
                            text: 'En continuant, vous acceptez nos ',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => launchUrl(
                                    Uri.parse('https://presentation.chapechaperesidence.com/conditions'),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: Text(
                                    'Conditions d\'utilisation',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: ' et notre ',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => launchUrl(
                                    Uri.parse('https://presentation.chapechaperesidence.com/politique-de-confidentialite'),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: Text(
                                    'Politique de confidentialité',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: '.',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      AppSpacing.verticalSmd,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bouton de connexion Google conforme (logo officiel multicolore sur fond blanc).
  Widget _googleLoginButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Image.asset(
                AppAssets.googleLogo,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.g_mobiledata, color: Colors.red, size: 24);
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuer avec Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}