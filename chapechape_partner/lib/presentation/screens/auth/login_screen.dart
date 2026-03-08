import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/common/buttons/primary_button.dart';
import '../../widgets/common/inputs/text_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = state is AuthLoading;
        });

        if (state is AuthFailure) {
          // UX type grandes apps : message court, barre sobre (pas de bannière rouge)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Illustration empty_connexion
                  Center(
                    child: Image.asset(
                      AppImages.emptyConnexion,
                      height: 120,
                      fit: BoxFit.contain,
                      semanticLabel: 'Illustration connexion',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Titre
                  Text(
                    'Connexion Partenaire',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour gérer vos résidences',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 20),
                  // Champ email
                  TextInput(
                    label: 'Email ou téléphone',
                    hint: 'Entrez votre email ou téléphone',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ce champ est requis';
                      }
                      
                      // Vérifier si c'est un email ou un téléphone
                      if (value.contains('@')) {
                        return FormValidators.validateEmail(value);
                      } else {
                        // Si ce n'est pas un email, c'est peut-être un téléphone
                        return FormValidators.validatePhoneNumber(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Champ mot de passe
                  TextInput(
                    label: 'Mot de passe',
                    hint: 'Entrez votre mot de passe',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    validator: (value) => FormValidators.validateRequired(value),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: _isLoading ? null : _togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lien mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.push('/auth/forgot-password'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        textStyle: const TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bouton de connexion
                  PrimaryButton(
                    text: 'Se connecter',
                    onPressed: _onLoginPressed,
                    isLoading: _isLoading,
                    filled: true,
                  ),
                  const SizedBox(height: 16),
                  // Lien inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas encore partenaire ?'),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.push('/auth/register'),
                        child: const Text('S\'inscrire'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Message légal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text.rich(
                      TextSpan(
                        text: 'En continuant, vous acceptez nos ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: Semantics(
                              label: 'Conditions d\'utilisation',
                              link: true,
                              child: InkWell(
                                onTap: () => launchUrl(
                                  Uri.parse('https://presentation.chapechaperesidence.com/conditions'),
                                  mode: LaunchMode.externalApplication,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  'Conditions d\'utilisation',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: ' et notre ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: Semantics(
                              label: 'Politique de confidentialité',
                              link: true,
                              child: InkWell(
                                onTap: () => launchUrl(
                                  Uri.parse('https://presentation.chapechaperesidence.com/politique-de-confidentialite'),
                                  mode: LaunchMode.externalApplication,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  'Politique de confidentialité',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: '.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
