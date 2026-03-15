import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/blocs/user/user_bloc.dart';
import 'package:chapechape_client/core/blocs/user/user_event.dart';
import 'package:chapechape_client/core/blocs/user/user_state.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isPasswordStrong = false;
  String _passwordStrengthMessage = '';
  double _passwordStrength = 0.0;
  Color _strengthColor = Colors.grey;
  
  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
    
    // Écouter les changements du nouveau mot de passe pour évaluer sa force
    _newPasswordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Évaluer la force du mot de passe
  void _checkPasswordStrength() {
    String password = _newPasswordController.text;
    
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthMessage = '';
        _strengthColor = Colors.grey;
        _isPasswordStrong = false;
      });
      return;
    }
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;
    
    double strength = 0.0;
    if (hasUppercase) strength += 0.2;
    if (hasLowercase) strength += 0.2;
    if (hasDigits) strength += 0.2;
    if (hasSpecialCharacters) strength += 0.2;
    if (hasMinLength) strength += 0.2;
    
    setState(() {
      _passwordStrength = strength;
      _isPasswordStrong = strength >= 0.8;
      
      if (strength < 0.3) {
        _passwordStrengthMessage = 'Très faible';
        _strengthColor = Colors.red;
      } else if (strength < 0.6) {
        _passwordStrengthMessage = 'Moyen';
        _strengthColor = Colors.orange;
      } else if (strength < 0.8) {
        _passwordStrengthMessage = 'Bon';
        _strengthColor = Colors.yellow.shade700;
      } else {
        _passwordStrengthMessage = 'Excellent';
        _strengthColor = Colors.green;
      }
    });
  }

  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _obscureCurrentPassword = !_obscureCurrentPassword;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _obscureNewPassword = !_obscureNewPassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Appliquer un retour haptique
      HapticFeedback.mediumImpact();
      
      context.read<UserBloc>().add(
        ChangeUserPassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserPasswordChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: AppSpacing.smd),
                    const Text('Mot de passe modifié avec succès'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.smd),
                ),
                margin: EdgeInsets.all(AppSpacing.smd),
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Animation de succès
            Future.delayed(const Duration(milliseconds: 500), () {
              context.pop();
            });
          } else if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: AppSpacing.smd),
                    Expanded(child: Text('Erreur: ${state.message}')),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.smd),
                ),
                margin: EdgeInsets.all(AppSpacing.smd),
              ),
            );
          }
        },
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            return Stack(
              children: [
                // Fond avec dégradé
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        AppTheme.lightGold.withOpacity(0.3),
                        Colors.white,
                      ],
                    ),
                  ),
                ),
                
                // Contenu principal
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête
                            Text(
                              'Changer votre\nmot de passe',
                              style: AppTheme.headingLarge.copyWith(
                                height: 1.2,
                              ),
                            ),
                            AppSpacing.verticalSm,
                            Text(
                              'Créez un mot de passe fort pour sécuriser votre compte',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                            AppSpacing.verticalLg,
                            
                            // Illustration empty state locale
                            Center(
                              child: Image.asset(
                                'assets/images/empty_states/empty_changemotpasse_illustration.png',
                                height: 160,
                                fit: BoxFit.contain,
                              ),
                            ),
                            AppSpacing.verticalLg,
                            
                            // Formulaire
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mot de passe actuel
                                  _buildPasswordField(
                                    controller: _currentPasswordController,
                                    labelText: 'Mot de passe actuel',
                                    obscureText: _obscureCurrentPassword,
                                    toggleVisibility: _toggleCurrentPasswordVisibility,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre mot de passe actuel';
                                      }
                                      return null;
                                    },
                                  ),
                                  AppSpacing.verticalLg,
                                  
                                  // Nouveau mot de passe
                                  _buildPasswordField(
                                    controller: _newPasswordController,
                                    labelText: 'Nouveau mot de passe',
                                    obscureText: _obscureNewPassword,
                                    toggleVisibility: _toggleNewPasswordVisibility,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer un nouveau mot de passe';
                                      }
                                      if (value.length < 8) {
                                        return 'Le mot de passe doit contenir au moins 8 caractères';
                                      }
                                      if (!_isPasswordStrong) {
                                        return 'Le mot de passe n\'est pas assez fort';
                                      }
                                      return null;
                                    },
                                  ),
                                  AppSpacing.verticalSm,
                                  
                                  // Indicateur de force du mot de passe
                                  if (_newPasswordController.text.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Force du mot de passe:',
                                              style: AppTheme.labelSmall,
                                            ),
                                            Text(
                                              _passwordStrengthMessage,
                                              style: AppTheme.labelSmall.copyWith(
                                                color: _strengthColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        AppSpacing.verticalSm,
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                                          child: LinearProgressIndicator(
                                            value: _passwordStrength,
                                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                                            minHeight: 6,
                                          ),
                                        ),
                                        AppSpacing.verticalSm,
                                        Text(
                                          'Utilisez au moins 8 caractères avec des lettres majuscules, minuscules, des chiffres et des caractères spéciaux',
                                          style: AppTheme.labelSmall.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  AppSpacing.verticalLg,
                                  
                                  // Confirmer le nouveau mot de passe
                                  _buildPasswordField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Confirmer le nouveau mot de passe',
                                    obscureText: _obscureConfirmPassword,
                                    toggleVisibility: _toggleConfirmPasswordVisibility,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez confirmer votre nouveau mot de passe';
                                      }
                                      if (value != _newPasswordController.text) {
                                        return 'Les mots de passe ne correspondent pas';
                                      }
                                      return null;
                                    },
                                  ),
                                  AppSpacing.verticalLg,
                                  
                                  // Bouton de soumission
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: state is UserLoading ? null : _submitForm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                        ),
                                      ),
                                      child: state is UserLoading
                                          ? SizedBox(
                                              width: AppSpacing.lg,
                                              height: AppSpacing.lg,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                              ),
                                            )
                                          : Text(
                                              'Mettre à jour le mot de passe',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: AppTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: AppTheme.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: AppTheme.errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          onPressed: toggleVisibility,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xs,
          vertical: AppSpacing.md + AppSpacing.xs,
        ),
      ),
      validator: validator,
      onChanged: (_) {
        if (controller == _newPasswordController) {
          _checkPasswordStrength();
        }
      },
    );
  }
}
