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

  /// Bouton Google (même style que login).
  Widget _googleLoginButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).colorScheme.surface,
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
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
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuer avec Google',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
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
            title: const SizedBox.shrink(),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/login'),
              tooltip: 'Retour à la connexion',
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Illustration : compacte, tout visible + fondu (comme login)
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
                                      'assets/images/empty_states/empty_inscription_illustration.png',
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
                        'Créer un compte',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalSm,
                      Text(
                        'Rejoignez ChapeChape pour trouver votre logement idéal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
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
                                SizedBox(width: AppSpacing.smd),
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
                                AppSpacing.verticalSmd,
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
                      AppSpacing.verticalSmd,
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Entrez votre adresse email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.validateEmail,
                      ),
                      AppSpacing.verticalSmd,
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
                      AppSpacing.verticalSmd,
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        validator: FormValidators.validatePassword,
                      ),
                      AppSpacing.verticalSmd,
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                        validator: (value) => FormValidators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),
                      AppSpacing.verticalSmd,
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
                      AppSpacing.verticalSmd,
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: state is AuthLoading ? 'Inscription en cours...' : 'S\'inscrire',
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
                            'Vous avez déjà un compte ?',
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
                              'Ou inscrivez-vous avec',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                      _googleLoginButton(
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            const GoogleLoginRequested(),
                          );
                        },
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
}