import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/common/buttons/primary_button.dart';
import '../../widgets/common/inputs/text_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          firstName: _companyNameController.text.trim(),
          lastName: "",
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
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
                  const SizedBox(height: 40),
                  // Logo
                  Center(
                    child: Image.asset(
                      AppImages.logoPrimary,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Titre
                  Text(
                    'Inscription Partenaire',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre compte partenaire pour commencer',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 40),
                  // Champs du formulaire
                  TextInput(
                    label: 'Nom de l\'entreprise',
                    hint: 'Entrez le nom de votre entreprise',
                    controller: _companyNameController,
                    enabled: !_isLoading,
                    validator: (value) => FormValidators.validateRequired(
                      value, 
                      fieldName: 'Le nom de l\'entreprise'
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextInput(
                    label: 'Email',
                    hint: 'Entrez votre email professionnel',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    validator: FormValidators.validateEmail,
                  ),
                  const SizedBox(height: 20),
                  TextInput(
                    label: 'Téléphone',
                    hint: 'Entrez votre numéro de téléphone',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_isLoading,
                    validator: FormValidators.validatePhoneNumber,
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 40),
                  // Bouton d'inscription
                  PrimaryButton(
                    text: 'S\'inscrire',
                    onPressed: _isLoading ? () {} : _onRegisterPressed,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),
                  // Lien connexion
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
