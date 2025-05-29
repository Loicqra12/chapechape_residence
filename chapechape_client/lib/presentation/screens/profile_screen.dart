import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_event.dart';
import 'package:chapechape_client/core/blocs/auth/auth_state.dart';
import 'package:chapechape_client/core/blocs/user/user_bloc.dart';
import 'package:chapechape_client/core/blocs/user/user_event.dart';
import 'package:chapechape_client/core/blocs/user/user_state.dart';
import 'package:chapechape_client/core/constants/app_assets.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/presentation/widgets/phone_verification_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  late TextEditingController _phoneController;
  
  bool _isEditing = false;
  bool _isVerifyingPhone = false;
  bool _phoneVerified = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    
    // Charger le profil utilisateur au démarrage
    context.read<UserBloc>().add(const LoadUserProfile());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData(UserProfileLoaded state) {
    _firstNameController.text = state.user.firstName;
    _lastNameController.text = state.user.lastName;
    _emailController.text = state.user.email;
    _phoneController.text = state.user.phoneNumber;
    
    // Déterminer si le téléphone est déjà vérifié
    setState(() {
      _phoneVerified = state.user.isPhoneVerified ?? false;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Vérifier si le numéro de téléphone a changé
      final currentState = context.read<UserBloc>().state;
      String? oldPhoneNumber;
      
      if (currentState is UserProfileLoaded) {
        oldPhoneNumber = currentState.user.phoneNumber;
      }
      
      // Si le numéro a changé, demander une vérification
      if (oldPhoneNumber != _phoneController.text) {
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
        phoneNumber: _phoneController.text,
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
      _phoneController.text = phoneNumber; // Mettre à jour avec le numéro vérifié
    });
    
    // Mettre à jour le profil avec le numéro vérifié
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
    context.read<AuthBloc>().add(const LogoutRequested());
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFFFFD700),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is Unauthenticated) {
            context.go('/onboarding');
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
              // Recharger le profil pour voir la nouvelle photo
              context.read<UserBloc>().add(const LoadUserProfile());
            }
          },
          builder: (context, state) {
            if (state is UserLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is UserProfileLoaded) {
              return _buildProfileContent(state);
            } else if (state is UserError) {
              return Center(child: Text('Erreur: ${state.message}'));
            } else {
              return const Center(child: CircularProgressIndicator());
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
            padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
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
                          ? NetworkImage(user.profilePicture!)
                          : NetworkImage(AppAssets.getDefaultAvatar(
                              name: '${user.firstName} ${user.lastName}',
                              size: 200,
                            )),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Nom complet
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                // Email
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Formulaire des informations
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isVerifyingPhone) ...[  
                    const SizedBox(height: 16),
                    const Text(
                      'Vérification du numéro de téléphone',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pour garantir la sécurité de votre compte et recevoir des notifications, veuillez vérifier votre numéro de téléphone.',
                    ),
                    const SizedBox(height: 16),
                    PhoneVerificationWidget(
                      initialPhoneNumber: _phoneController.text,
                      onVerificationSuccess: _onPhoneVerified,
                    ),
                  ] else ...[  
                    const SizedBox(height: 16),
                    const Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  // Prénom
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(height: 15),
                  
                  // Nom
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(height: 15),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    enabled: false, // L'email ne peut pas être modifié
                  ),
                  const SizedBox(height: 15),
                  
                  // Téléphone
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          enabled: _isEditing,
                          decoration: InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: const Icon(Icons.phone),
                            suffixIcon: _phoneVerified
                                ? const Icon(Icons.verified, color: Colors.green)
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre numéro de téléphone';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_isEditing && !_phoneVerified) ...[  
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _startPhoneVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text('Vérifier'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isEditing) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Enregistrer', style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _toggleEdit,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
                              backgroundColor: AppTheme.secondaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Modifier le profil', style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Autres options
                  _buildOptionTile(
                    icon: Icons.lock,
                    title: 'Changer le mot de passe',
                    onTap: () {
                      context.push('/password-change');
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.account_balance_wallet,
                    title: 'Portefeuille et récompenses',
                    onTap: () {
                      context.push('/profile/wallet');
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.payment,
                    title: 'Moyens de paiement',
                    onTap: () {
                      context.push('/profile/payment-methods');
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: Icons.history,
                    title: 'Historique des réservations',
                    onTap: () {
                      context.read<UserBloc>().add(const LoadBookingHistory());
                      context.go('/bookings');
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
                  
                  const SizedBox(height: 30),
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
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}