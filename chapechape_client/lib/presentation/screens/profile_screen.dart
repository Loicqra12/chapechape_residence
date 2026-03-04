import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_event.dart';
import 'package:chapechape_client/core/blocs/auth/auth_state.dart';
import 'package:chapechape_client/core/blocs/user/user_bloc.dart';
import 'package:chapechape_client/core/blocs/user/user_event.dart';
import 'package:chapechape_client/core/blocs/user/user_state.dart';
import 'package:chapechape_client/core/constants/app_assets.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/config/app_config_manager.dart';
import 'package:chapechape_client/presentation/widgets/phone_verification_widget.dart';
import 'package:chapechape_client/presentation/widgets/common/inputs/advanced_phone_input_widget.dart';
import 'package:chapechape_client/core/models/phone_number.dart';
import 'package:chapechape_client/presentation/widgets/skeletons/profile_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  
  bool _isEditing = false;
  bool _isVerifyingPhone = false;
  bool _phoneVerified = false;
  
  // Variables pour le widget de téléphone avancé
  PhoneNumber? _selectedPhoneNumber;
  String _phoneE164 = ''; // Conserver le numéro en format E.164 complet
  bool _isPhoneValid = false;
  
  final ImagePicker _picker = ImagePicker();

  /// Normalise un numéro de téléphone au format E.164
  String _normalizeToE164(String phoneNumber, String countryCode) {
    if (phoneNumber.startsWith('+')) {
      return phoneNumber; // Déjà en format E.164
    }
    
    // Mapping des codes pays
    final countryCodeMap = {
      'CI': '+225',
      'SN': '+221', 
      'ML': '+223',
      'BF': '+226',
      'GN': '+224',
    };
    
    final prefix = countryCodeMap[countryCode] ?? '+225';
    return '$prefix$phoneNumber';
  }

  /// Parse un numéro E.164 pour extraire le code pays et le numéro national
  Map<String, String> _parseE164(String phoneE164) {
    if (phoneE164.startsWith('+225')) {
      return {'isoCode': 'CI', 'nationalNumber': phoneE164.substring(4)};
    } else if (phoneE164.startsWith('+221')) {
      return {'isoCode': 'SN', 'nationalNumber': phoneE164.substring(4)};
    } else if (phoneE164.startsWith('+223')) {
      return {'isoCode': 'ML', 'nationalNumber': phoneE164.substring(4)};
    } else if (phoneE164.startsWith('+226')) {
      return {'isoCode': 'BF', 'nationalNumber': phoneE164.substring(4)};
    } else if (phoneE164.startsWith('+224')) {
      return {'isoCode': 'GN', 'nationalNumber': phoneE164.substring(4)};
    }
    
    // Par défaut, Côte d'Ivoire
    return {'isoCode': 'CI', 'nationalNumber': phoneE164.replaceFirst('+', '')};
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    
    // Charger le profil utilisateur au démarrage
    context.read<UserBloc>().add(const LoadUserProfile());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData(UserProfileLoaded state) {
    _firstNameController.text = state.user.firstName;
    _lastNameController.text = state.user.lastName;
    _emailController.text = state.user.email;
    
    // Initialiser le numéro de téléphone pour le widget avancé
    if (state.user.phoneNumber.isNotEmpty) {
      // Conserver la version E.164 originale
      _phoneE164 = state.user.phoneNumber.startsWith('+') 
          ? state.user.phoneNumber 
          : _normalizeToE164(state.user.phoneNumber, 'CI');
      
      // Parser pour l'affichage dans le widget
      final parsed = _parseE164(_phoneE164);
      _selectedPhoneNumber = PhoneNumber(
        isoCode: parsed['isoCode']!, 
        phoneNumber: parsed['nationalNumber']!,
        dialCode: _phoneE164.substring(0, 4)
      );
    }
    
    // Déterminer si le téléphone est déjà vérifié (SANS setState pour éviter les boucles)
    _phoneVerified = state.user.isPhoneVerified ?? false;
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Mettre à jour le numéro E.164 basé sur la sélection actuelle
      if (_selectedPhoneNumber != null) {
        _phoneE164 = _normalizeToE164(
          _selectedPhoneNumber!.phoneNumber, 
          _selectedPhoneNumber!.isoCode
        );
      }
      
      // Vérifier si le numéro de téléphone a changé (comparaison E.164)
      final currentState = context.read<UserBloc>().state;
      String oldPhoneE164 = '';
      
      if (currentState is UserProfileLoaded) {
        oldPhoneE164 = currentState.user.phoneNumber.startsWith('+') 
            ? currentState.user.phoneNumber 
            : _normalizeToE164(currentState.user.phoneNumber, 'CI');
      }
      
      // Si le numéro a changé, demander une vérification
      if (oldPhoneE164 != _phoneE164) {
        setState(() {
          _isVerifyingPhone = true;
          _phoneVerified = false;
        });
        return;
      }
      
      // Sinon, sauvegarder le profil normalement
      _updateUserProfile();
    }
  }
  
  void _updateUserProfile() {
    context.read<UserBloc>().add(
      UpdateUserProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneE164, // Envoyer le numéro en format E.164
        isPhoneVerified: _phoneVerified,
      ),
    );
    
    setState(() {
      _isEditing = false;
      _isVerifyingPhone = false;
    });
  }
  
  void _startPhoneVerification() {
    setState(() {
      _isVerifyingPhone = true;
    });
  }
  
  void _onPhoneVerified(String phoneNumber) {
    setState(() {
      _phoneVerified = true;
      _isVerifyingPhone = false;
      
      // Mettre à jour le numéro E.164 avec le numéro vérifié
      _phoneE164 = phoneNumber.startsWith('+') ? phoneNumber : _normalizeToE164(phoneNumber, 'CI');
      
      // Parser pour l'affichage dans le widget
      final parsed = _parseE164(_phoneE164);
      _selectedPhoneNumber = PhoneNumber(
        isoCode: parsed['isoCode']!, 
        phoneNumber: parsed['nationalNumber']!,
        dialCode: _phoneE164.substring(0, 4)
      );
    });
    
    // Mettre à jour le profil avec le numéro vérifié en E.164
    _updateUserProfile();
    
    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Numéro de téléphone vérifié avec succès')),
    );
  }
  
  void _cancelPhoneVerification() {
    setState(() {
      _isVerifyingPhone = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      context.read<UserBloc>().add(UploadProfilePicture(image.path));
    }
  }

  void _logout() {
    HapticFeedback.mediumImpact();
    context.read<AuthBloc>().add(const LogoutRequested());
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is Unauthenticated) {
            context.go('/home');
          }
        },
        child: BlocConsumer<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserProfileLoaded) {
              _loadUserData(state);
            } else if (state is UserProfileUpdated) {
              _loadUserData(UserProfileLoaded(state.user));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil mis à jour avec succès')),
              );
            } else if (state is UserError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: ${state.message}')),
              );
            } else if (state is ProfilePictureUploaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo de profil mise à jour')),
              );
              // Note: Pas de rechargement automatique pour éviter les boucles de layout
              // Le profil sera rafraîchi au prochain rebuild naturel
            }
          },
          builder: (context, state) {
            if (state is UserLoading) {
              return const ProfileSkeleton();
            } else if (state is UserProfileLoaded) {
              return _buildProfileContent(state);
            } else if (state is UserError) {
              return Center(child: Text('Erreur: ${state.message}'));
            } else {
              return const ProfileSkeleton();
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(UserProfileLoaded state) {
    final user = state.user;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête du profil avec photo
          Container(
            padding: EdgeInsets.only(top: AppSpacing.xxl40 + AppSpacing.xxs, bottom: AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Photo de profil
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: user.profilePicture != null
                          ? NetworkImage(AppConfigManager.getProfileImageUrl(user.profilePicture!))
                          : NetworkImage(AppAssets.getDefaultAvatar(
                              name: '${user.firstName} ${user.lastName}',
                              size: 200,
                            )),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.textLight,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, size: 20, color: AppTheme.textPrimary),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md15), // 15px pour espacement spécifique
                // Nom complet
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs5), // 5px pour espacement spécifique
                // Email
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                AppSpacing.verticalLg,
              ],
            ),
          ),

          // Formulaire des informations
          Padding(
            padding: AppSpacing.cardPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isVerifyingPhone) ...[  
                    AppSpacing.verticalMd,
                    Text(
                      'Vérification du numéro de téléphone',
                      style: AppTextStyles.subtitle,
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      'Pour garantir la sécurité de votre compte et recevoir des notifications, veuillez vérifier votre numéro de téléphone.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    AppSpacing.verticalMd,
                    PhoneVerificationWidget(
                      initialPhoneNumber: _selectedPhoneNumber?.phoneNumber ?? '',
                      onVerificationSuccess: _onPhoneVerified,
                    ),
                  ] else ...[  
                    AppSpacing.verticalMd,
                    Text(
                      'Informations personnelles',
                      style: AppTextStyles.subtitle,
                    ),
                  AppSpacing.verticalLg,
                  
                  // Prénom
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - AppSpacing.xs),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre prénom';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.md15), // 15px pour espacement spécifique
                  
                  // Nom
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - AppSpacing.xs),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    enabled: _isEditing,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.md15), // 15px pour espacement spécifique
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - AppSpacing.xs),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    enabled: false, // L'email ne peut pas être modifié
                  ),
                  SizedBox(height: AppSpacing.md15), // 15px pour espacement spécifique
                  
                  // Téléphone avec widget avancé
                  if (_isEditing) ...[
                    AdvancedPhoneInputWidget(
                      label: 'Téléphone',
                      hint: 'Entrez votre numéro de téléphone',
                      isRequired: true,
                      initialPhoneNumber: _selectedPhoneNumber,
                      readOnly: !_isEditing,
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
                    if (!_phoneVerified) ...[
                      AppSpacing.verticalSm,
                      ElevatedButton(
                        onPressed: _isPhoneValid ? _startPhoneVerification : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.textLight,
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.smd, vertical: AppSpacing.sm),
                        ),
                        child: const Text('Vérifier le numéro'),
                      ),
                    ],
                  ] else ...[
                    // Affichage en lecture seule
                    Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerColor),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: AppTheme.textSecondary),
                          SizedBox(width: AppSpacing.smd),
                          Expanded(
                            child: Text(
                              _selectedPhoneNumber?.phoneNumber ?? 'Non renseigné',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          if (_phoneVerified)
                            Icon(Icons.verified, color: AppTheme.successColor),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.xl30), // 30px pour espacement spécifique
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isEditing) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md15), // 15px
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                            ),
                            child: Text(
                              'Enregistrer',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textLight,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm10), // 10px pour espacement spécifique
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _toggleEdit,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md15), // 15px
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.md15), // 15px
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                            ),
                            child: Text(
                              'Modifier le profil',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  AppSpacing.verticalLg,
                  
                  // Autres options
                  _buildOptionTile(
                    icon: Icons.lock,
                    title: 'Changer le mot de passe',
                    onTap: () {
                      context.push('/password-change');
                    },
                  ),
                  
                  // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
                  // _buildOptionTile(
                  //   icon: Icons.account_balance_wallet,
                  //   title: 'Portefeuille et récompenses',
                  //   onTap: () {
                  //     context.push('/profile/wallet');
                  //   },
                  // ),
                  
                  // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
                  // _buildOptionTile(
                  //   icon: Icons.payment,
                  //   title: 'Moyens de paiement',
                  //   onTap: () {
                  //     context.push('/profile/payment-methods');
                  //   },
                  // ),
                  
                  _buildOptionTile(
                    icon: Icons.history,
                    title: 'Historique des réservations',
                    onTap: () {
                      context.read<UserBloc>().add(const LoadBookingHistory());
                      context.push('/bookings');
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.favorite,
                    title: 'Résidences favorites',
                    onTap: () {
                      context.read<UserBloc>().add(const LoadFavoriteResidences());
                      context.go('/favorites');
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.settings,
                    title: 'Paramètres',
                    onTap: () {
                      context.push('/profile/settings');
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.help,
                    title: 'Aide et support',
                    onTap: () {
                      context.push('/profile/help');
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.home_work,
                    title: 'Inscrire votre résidence',
                    onTap: () {
                      // À compléter avec le lien vers l'application partenaire
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité en cours de développement. Disponible prochainement!'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    isDestructive: true,
                    onTap: _logout,
                  ),
                  
                  SizedBox(height: AppSpacing.xl30), // 30px pour espacement spécifique
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      // onTap handled in ListTile property above
    );
  }
}
