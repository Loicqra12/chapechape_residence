import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_event.dart';
import 'package:chapechape_client/core/blocs/auth/auth_state.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
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
            title: const Text('Connexion'),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 80,
                          child: Image.asset(
                            'assets/logos/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Bienvenue sur ChapeChape Résidences',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connectez-vous pour accéder à votre compte',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Entrez votre adresse email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.validateEmail,
                        onSaved: (value) => _email = value ?? '',
                      ),
                      const SizedBox(height: 20),
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
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        validator: FormValidators.validatePassword,
                        onSaved: (value) => _password = value ?? '',
                      ),
                      const SizedBox(height: 16),
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
                                const SizedBox(width: 8),
                                const Flexible(
                                  child: Text(
                                    'Se souvenir de moi',
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
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                minimumSize: const Size(0, 36),
                              ),
                              child: Text(
                                'Mot de passe oublié?',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: state is AuthLoading ? 'Connexion en cours...' : 'Se connecter',
                          isLoading: state is AuthLoading,
                          onPressed: state is AuthLoading ? null : _submitForm,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Vous n\'avez pas de compte?'),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              'S\'inscrire',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Ou connectez-vous avec',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialLoginButton(
                            icon: 'logos/google_logo.png',
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                const GoogleLoginRequested(),
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          _socialLoginButton(
                            icon: 'logos/facebook_logo.png',
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                const FacebookLoginRequested(),
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          _socialLoginButton(
                            icon: 'logos/apple_logo.png',
                            onPressed: () {
                              // Implémenter la connexion avec Apple
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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

  Widget _socialLoginButton({required String icon, required VoidCallback onPressed}) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(
                  icon == 'logos/google_logo.png' ? Icons.g_mobiledata : 
                  icon == 'logos/facebook_logo.png' ? Icons.facebook : 
                  Icons.apple,
                  size: 24,
                  color: icon == 'logos/google_logo.png' ? Colors.red : 
                         icon == 'logos/facebook_logo.png' ? Colors.blue : 
                         Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}