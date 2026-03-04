import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import '../../../core/utils/validators/form_validators.dart';
import '../../widgets/common/buttons/primary_button.dart';
import '../../widgets/common/inputs/text_input.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  void _changePassword() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      // Préparer les données à envoyer
      final passwordData = {
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      };
      
      // Envoyer l'événement de mise à jour du mot de passe
      context.read<AuthBloc>().add(
        UpdateProfileRequested(userData: {'password': passwordData}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is AuthAuthenticated) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state is AuthFailure) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: const Text('Changer le mot de passe'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explications
                Text(
                  'Vous pouvez changer votre mot de passe ici. Veuillez entrer votre mot de passe actuel pour confirmer.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Mot de passe actuel
                TextInput(
                  label: 'Mot de passe actuel',
                  hint: 'Entrez votre mot de passe actuel',
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  enabled: !_isLoading,
                  validator: FormValidators.validateRequired,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _isLoading ? () {} : _toggleCurrentPasswordVisibility,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Nouveau mot de passe
                TextInput(
                  label: 'Nouveau mot de passe',
                  hint: 'Entrez votre nouveau mot de passe',
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  enabled: !_isLoading,
                  validator: FormValidators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _isLoading ? () {} : _toggleNewPasswordVisibility,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Confirmation du nouveau mot de passe
                TextInput(
                  label: 'Confirmer le mot de passe',
                  hint: 'Confirmez votre nouveau mot de passe',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !_isLoading,
                  validator: (value) => FormValidators.validatePasswordConfirmation(
                    value, 
                    _newPasswordController.text,
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
                const SizedBox(height: 32),
                
                // Informations sur le mot de passe
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exigences pour le mot de passe :',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bulletPoint('Au moins 8 caractères'),
                      _bulletPoint('Au moins une lettre majuscule'),
                      _bulletPoint('Au moins une lettre minuscule'),
                      _bulletPoint('Au moins un chiffre'),
                      _bulletPoint('Au moins un caractère spécial (!@#\$%^&*(),.?":{}|<>)'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Bouton de validation
                PrimaryButton(
                  text: 'Changer le mot de passe',
                  onPressed: _isLoading ? () {} : _changePassword,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
} 