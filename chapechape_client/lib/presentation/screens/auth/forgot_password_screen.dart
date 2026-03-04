import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_event.dart';
import 'package:chapechape_client/core/blocs/auth/auth_state.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/utils/form_validators.dart';
import 'package:chapechape_client/presentation/widgets/custom_button.dart';
import 'package:chapechape_client/presentation/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequested(
              email: _emailController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            setState(() {
              _emailSent = true;
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_emailSent) {
            return _buildSuccessView();
          }
          
          return _buildFormView(state);
        },
      ),
    );
  }

  Widget _buildFormView(AuthState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.verticalMd,
              Image.asset(
                'assets/images/forgot_password.png',
                height: 150,
              ),
              AppSpacing.verticalLg,
              Text(
                'Mot de passe oublié ?',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalMd,
              Text(
                'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalXl,
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Entrez votre adresse email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.validateEmail,
              ),
              AppSpacing.verticalLg,
              CustomButton(
                text: state is AuthLoading ? 'Envoi en cours...' : 'Envoyer le lien',
                isLoading: state is AuthLoading,
                onPressed: state is AuthLoading ? null : _submitForm,
              ),
              AppSpacing.verticalMd,
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Retour à la connexion',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 100,
            color: Colors.green,
          ),
          AppSpacing.verticalLg,
          Text(
            'Email envoyé !',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalMd,
          Text(
            'Nous avons envoyé un lien de réinitialisation à ${_emailController.text}. Veuillez vérifier votre boîte de réception.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalXl,
          CustomButton(
            text: 'Retour à la connexion',
            onPressed: () => context.go('/login'),
          ),
          AppSpacing.verticalMd,
          TextButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
              });
            },
            child: Text(
              'Essayer avec une autre adresse email',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
