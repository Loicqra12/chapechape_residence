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
import 'package:chapechape_client/core/utils/form_validators.dart';
import 'package:chapechape_client/core/services/error_message_service.dart';
import 'package:chapechape_client/presentation/widgets/custom_button.dart';
import 'package:chapechape_client/presentation/widgets/custom_text_field.dart';
import 'package:chapechape_client/presentation/widgets/common/inputs/advanced_phone_input_widget.dart';
import 'package:chapechape_client/core/models/phone_number.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  
  // Variables pour le widget de téléphone avancé
  PhoneNumber? _selectedPhoneNumber;
  bool _isPhoneValid = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _selectedPhoneNumber?.completeNumber ?? '',
              password: _passwordController.text,
            ),
          );
    } else if (!_acceptTerms) {
      ErrorMessageService.showWarning(
        context,
        'Veuillez accepter les conditions d\'utilisation pour continuer.',
      );
    }
  }

  Widget _socialLoginButton({required String icon, required VoidCallback onPressed}) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.smd),
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
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ErrorMessageService.showError(
            context,
            state.message,
            contextType: 'register',
            onRetry: _submitForm,
          );
        } else if (state is RegisterSuccess) {
          ErrorMessageService.showSuccess(
            context,
            'Inscription réussie ! Vous pouvez maintenant vous connecter.',
          );
          context.go('/login');
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inscription'),
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
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSpacing.verticalMd,
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
                      AppSpacing.verticalLg,
                      Text(
                        'Créer un compte',
                        style: AppTextStyles.title,
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalSm,
                      Text(
                        'Rejoignez ChapeChape Résidences pour trouver votre logement idéal',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalLg,
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // Vue large - afficher les champs côte à côte
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _firstNameController,
                                    labelText: 'Prénom',
                                    hintText: 'Votre prénom',
                                    prefixIcon: Icons.person_outline,
                                    validator: FormValidators.validateName,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _lastNameController,
                                    labelText: 'Nom',
                                    hintText: 'Votre nom',
                                    prefixIcon: Icons.person_outline,
                                    validator: FormValidators.validateName,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Vue étroite - empiler les champs
                            return Column(
                              children: [
                                CustomTextField(
                                  controller: _firstNameController,
                                  labelText: 'Prénom',
                                  hintText: 'Votre prénom',
                                  prefixIcon: Icons.person_outline,
                                  validator: FormValidators.validateName,
                                ),
                                AppSpacing.verticalMd,
                                CustomTextField(
                                  controller: _lastNameController,
                                  labelText: 'Nom',
                                  hintText: 'Votre nom',
                                  prefixIcon: Icons.person_outline,
                                  validator: FormValidators.validateName,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      AppSpacing.verticalMd,
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Entrez votre adresse email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.validateEmail,
                      ),
                      AppSpacing.verticalMd,
                      AdvancedPhoneInputWidget(
                        label: 'Téléphone',
                        hint: 'Entrez votre numéro de téléphone',
                        isRequired: true,
                        onPhoneChanged: (PhoneNumber phoneNumber) {
                          setState(() {
                            _selectedPhoneNumber = phoneNumber;
                          });
                        },
                        onValidationChanged: (bool isValid) {
                          setState(() {
                            _isPhoneValid = isValid;
                          });
                        },
                        themeColor: Theme.of(context).primaryColor,
                      ),
                      AppSpacing.verticalMd,
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Mot de passe',
                        hintText: 'Créez un mot de passe',
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
                      ),
                      AppSpacing.verticalMd,
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirmer le mot de passe',
                        hintText: 'Confirmez votre mot de passe',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                        validator: (value) => FormValidators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),
                      AppSpacing.verticalMd,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: AppSpacing.lg,
                            width: AppSpacing.lg,
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: RichText(
                              overflow: TextOverflow.visible,
                              text: TextSpan(
                                text: 'J\'accepte les ',
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => launchUrl(
                                        Uri.parse('https://presentation.chapechaperesidence.com/conditions'),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Text(
                                        'conditions d\'utilisation',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' et la ',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => launchUrl(
                                        Uri.parse('https://presentation.chapechaperesidence.com/politique-de-confidentialite'),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Text(
                                        'politique de confidentialité',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalLg,
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: state is AuthLoading ? 'Inscription en cours...' : 'S\'inscrire',
                          isLoading: state is AuthLoading,
                          onPressed: state is AuthLoading ? null : _submitForm,
                        ),
                      ),
                      AppSpacing.verticalMd,
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Vous avez déjà un compte?',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/login');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              'Se connecter',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalLg,
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
                              'Ou inscrivez-vous avec',
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
                      AppSpacing.verticalLg,
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
                          SizedBox(width: AppSpacing.md),
                          _socialLoginButton(
                            icon: 'logos/facebook_logo.png',
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                const FacebookLoginRequested(),
                              );
                            },
                          ),
                          SizedBox(width: AppSpacing.md),
                          _socialLoginButton(
                            icon: 'logos/apple_logo.png',
                            onPressed: () {
                              // Implémenter la connexion avec Apple
                            },
                          ),
                        ],
                      ),
                      AppSpacing.verticalMd,
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
}