
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
import '../../widgets/common/inputs/advanced_phone_input_widget.dart';
import '../../../core/models/phone_number.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  // Variables pour le widget de téléphone avancé
  PhoneNumber? _selectedPhoneNumber;
  bool _isPhoneValid = false;
  String _selectedCountryCode = 'CI'; // Code pays par défaut
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    // _phoneController supprimé car remplacé par AdvancedPhoneInputWidget
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      // Valider que les champs obligatoires sont remplis
      String firstName = _firstNameController.text.trim();
      String lastName = _lastNameController.text.trim();
      
      // Les noms sont obligatoires, pas de fallback automatique
      if (firstName.isEmpty || lastName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prénom et nom sont obligatoires', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
        return;
      }

      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          firstName: firstName,
          lastName: lastName,
          email: _emailController.text.trim(),
          phoneNumber: _selectedPhoneNumber?.completeNumber ?? '',
          password: _passwordController.text,
          countryCode: _selectedCountryCode, // Passer le code pays
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: const TextStyle(color: Colors.white)),
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
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Illustration (hauteur réduite pour tenir sur une page)
                  Center(
                    child: Image.asset(
                      AppImages.emptyRegister,
                      height: 100,
                      fit: BoxFit.contain,
                      semanticLabel: 'Illustration inscription',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Inscription Partenaire',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inscrivez-vous pour commencer à gérer vos résidences et à développer votre activité.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 14),
                  // Champs du formulaire
                  TextInput(
                    label: 'Prénom',
                    hint: 'Entrez votre prénom',
                    controller: _firstNameController,
                    enabled: !_isLoading,
                    validator: (value) => FormValidators.validateRequired(
                      value,
                      fieldName: 'Le prénom',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextInput(
                    label: 'Nom',
                    hint: 'Entrez votre nom',
                    controller: _lastNameController,
                    enabled: !_isLoading,
                    validator: (value) => FormValidators.validateRequired(
                      value,
                      fieldName: 'Le nom',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextInput(
                    label: 'Email',
                    hint: 'Entrez votre email professionnel',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    validator: FormValidators.validateEmail,
                  ),
                  const SizedBox(height: 10),
                  AdvancedPhoneInputWidget(
                    label: 'Téléphone',
                    hint: 'Entrez votre numéro de téléphone',
                    enabled: !_isLoading,
                    isRequired: true,
                    themeColor: Theme.of(context).primaryColor,
                    onPhoneChanged: (PhoneNumber phoneNumber) {
                      setState(() {
                        _selectedPhoneNumber = phoneNumber;
                        _selectedCountryCode = phoneNumber.isoCode; // Extraire le code pays
                      });
                    },
                    onValidationChanged: (bool isValid) {
                      setState(() {
                        _isPhoneValid = isValid;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextInput(
                    label: 'Mot de passe',
                    hint: 'Créez votre mot de passe',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    validator: FormValidators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: _isLoading ? () {} : _togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextInput(
                    label: 'Confirmer le mot de passe',
                    hint: 'Confirmez votre mot de passe',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    validator: (value) => FormValidators.validatePasswordConfirmation(
                      value, 
                      _passwordController.text
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: _isLoading ? () {} : _toggleConfirmPasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: 'S\'inscrire',
                    onPressed: _isLoading ? () {} : _onRegisterPressed,
                    isLoading: _isLoading,
                    filled: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Déjà partenaire ?'),
                      TextButton(
                        onPressed: _isLoading ? () {} : () => context.push('/auth/login'),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                      TextSpan(
                        text: 'En vous inscrivant, vous acceptez nos ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
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
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
                            child: GestureDetector(
                              onTap: () => launchUrl(
                                Uri.parse('https://presentation.chapechaperesidence.com/politique-de-confidentialite'),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(
                                'Politique de confidentialité',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
