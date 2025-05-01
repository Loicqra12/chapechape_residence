import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/amenities_widget.dart';
import 'package:intl/intl.dart';
import '../screens/booking_screen.dart';  // Import de BookingScreen pour la navigation directe
import '../../core/blocs/booking/booking_bloc.dart';
import '../../core/services/booking_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/currency_service.dart';
import '../widgets/currency_selector_widget.dart';

class ResidenceDetailsScreen extends StatefulWidget {
  final String residenceId;
  
  const ResidenceDetailsScreen({super.key, required this.residenceId});

  @override
  State<ResidenceDetailsScreen> createState() => _ResidenceDetailsScreenState();
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> {
  // Image par défaut quand aucune image n'est disponible
  final String defaultImage = 'assets/images/residences/apartments/304661255.jpg';

  @override
  void initState() {
    super.initState();
    // Charger les détails de la résidence
    context.read<ResidenceBloc>().add(LoadResidenceDetails(residenceId: widget.residenceId));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Restaurer l'état précédent avant de revenir en arrière
        context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
        return true;
      },
      child: Scaffold(
        body: BlocBuilder<ResidenceBloc, ResidenceState>(
          builder: (context, state) {
            if (state is ResidenceLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ResidenceDetailsLoaded) {
              final residence = state.residence;
              
              return CustomScrollView(
                slivers: [
                  // AppBar avec image en arrière-plan
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: residence.images.isNotEmpty
                          ? Image.network(
                              residence.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  defaultImage,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              defaultImage,
                              fit: BoxFit.cover,
                            ),
                    ),
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.black,
                        onPressed: () {
                          // Utiliser RefreshResidencesEvent au lieu de RestorePreviousStateEvent
                          context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    actions: [
                      // Bouton de favoris (nécessite authentification)
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          return Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                residence.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: residence.isFavorite ? Colors.red : Colors.black,
                              ),
                              onPressed: () {
                                if (authState is Authenticated) {
                                  // Ajouter/retirer des favoris
                                  context.read<ResidenceBloc>().add(
                                    ToggleFavorite(
                                      residenceId: residence.id,
                                    ),
                                  );
                                } else {
                                  // Inviter à se connecter
                                  _showAuthDialog(context);
                                }
                              },
                            ),
                          );
                        },
                      ),
                      // Bouton de partage
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          color: Colors.black,
                          onPressed: () {
                            // Logique de partage
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  // Contenu principal
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre et prix
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  residence.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    residence.formattedPrice,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Ajouter un bouton pour changer la devise
                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) => CurrencySelectorBottomSheet(
                                          onCurrencyChanged: (newCurrency) {
                                            // Forcer la mise à jour de l'UI
                                            setState(() {});
                                          },
                                        ),
                                      );
                                    },
                                    child: const Icon(Icons.currency_exchange, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Si un prix avec remise existe, ajouter:
                          if (residence.hasDiscount)
                            Row(
                              children: [
                                Text(
                                  residence.formattedDiscountPrice,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  residence.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    residence.discountBadge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          
                          // Adresse
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  residence.location['displayAddress'] ?? residence.address,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          // Caractéristiques principales
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildFeatureItem(
                                icon: Icons.king_bed_outlined,
                                label: '${residence.bedrooms} chambres',
                              ),
                              _buildFeatureItem(
                                icon: Icons.bathroom_outlined,
                                label: '${residence.bathrooms} salles de bain',
                              ),
                              _buildFeatureItem(
                                icon: Icons.straighten_outlined,
                                label: '${residence.surface} m²',
                              ),
                            ],
                          ),
                          
                          // Statut de disponibilité
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: residence.isAvailable ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              residence.isAvailable ? 'Disponible' : 'Non disponible',
                              style: TextStyle(
                                color: residence.isAvailable ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Description
                          const SizedBox(height: 24),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            residence.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          
                          // Équipements
                          const SizedBox(height: 24),
                          const Text(
                            'Équipements',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          residence.amenities.isNotEmpty
                              ? AmenitiesWidget(
                                  amenities: residence.amenities,
                                  isDetailed: true,
                                )
                              : const Text('Aucun équipement spécifié'),
                          
                          // Règles
                          if (residence.rules != null && residence.rules!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Règles',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...?residence.rules?.map((rule) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rule, style: const TextStyle(fontSize: 16))),
                                ],
                              ),
                            )),
                          ],
                          
                          // Si nécessaire, ajouter des champs pour afficher le prix dans différentes devises
                          FutureBuilder<String>(
                            future: () async {
                              final currencyService = CurrencyService();
                              await currencyService.initialize();
                              
                              // Afficher le prix dans EUR si la devise actuelle n'est pas déjà EUR
                              if (currencyService.currentCurrency != 'EUR' && residence.currency != 'EUR') {
                                return residence.getFormattedPriceIn('EUR');
                              }
                              
                              // Afficher le prix dans USD si la devise actuelle n'est pas déjà USD
                              if (currencyService.currentCurrency != 'USD' && residence.currency != 'USD') {
                                return residence.getFormattedPriceIn('USD');
                              }
                              
                              return '';
                            }(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && 
                                  snapshot.hasData && 
                                  snapshot.data!.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Soit environ ${snapshot.data}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          
                          const SizedBox(height: 100), // Espace pour le bouton flottant
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else if (state is ResidenceError) {
              return Center(child: Text('Erreur: ${state.message}'));
            } else {
              return const Center(child: Text('Aucune donnée disponible'));
            }
          },
        ),
        // Bouton de réservation flottant
        floatingActionButton: BlocBuilder<ResidenceBloc, ResidenceState>(
          builder: (context, state) {
            if (state is ResidenceDetailsLoaded) {
              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  return FloatingActionButton.extended(
                    onPressed: state.residence.id.isEmpty 
                      ? null // Désactiver le bouton si l'ID est vide
                      : () async {
                          if (authState is Authenticated) {
                            // Déboguer l'ID de résidence
                            debugPrint('ID de résidence pour réservation: ${state.residence.id}');
                            if (state.residence.id.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erreur: ID de résidence manquant. Cette résidence ne peut pas être réservée.'),
                                  duration: Duration(seconds: 5),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // Initialiser le BookingService avant de créer le BookingBloc
                            final bookingService = await BookingService.initialize();
                            
                            // Utiliser BlocProvider pour fournir le BookingBloc à l'écran de réservation
                            if (!mounted) return; // Vérifier si le widget est toujours monté
                            
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider<BookingBloc>(
                                      create: (context) => BookingBloc(
                                        bookingService: bookingService,
                                      ),
                                    ),
                                    // Réutiliser le ResidenceBloc existant
                                    BlocProvider.value(
                                      value: context.read<ResidenceBloc>(),
                                    ),
                                  ],
                                  child: BookingScreen(
                                    residenceId: state.residence.id,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Afficher la boîte de dialogue d'authentification
                            _showAuthDialog(context);
                          }
                        },
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    label: Text(
                      authState is Authenticated ? 'Réserver maintenant' : 'Se connecter pour réserver',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.calendar_today),
                  );
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String label}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez être connecté pour réserver cette résidence ou l\'ajouter à vos favoris.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}