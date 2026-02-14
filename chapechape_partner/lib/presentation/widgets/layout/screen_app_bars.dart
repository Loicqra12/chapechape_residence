import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_partner/core/constants/app_icons.dart';
import 'package:chapechape_partner/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_partner/core/blocs/auth/auth_event.dart';
import 'package:chapechape_partner/core/blocs/dashboard/dashboard_bloc.dart';
import 'package:chapechape_partner/core/blocs/residence/residence_bloc.dart';
import 'package:chapechape_partner/core/blocs/message/message_bloc.dart';
import 'package:chapechape_partner/core/blocs/reservation/reservation_bloc.dart';
import 'package:chapechape_partner/core/blocs/notification/notification_bloc.dart';
import 'package:chapechape_partner/core/blocs/notification/notification_state.dart';
import 'package:chapechape_partner/core/theme/colors.dart';
import 'package:chapechape_partner/presentation/widgets/dashboard/dashboard_filter_sheet.dart';
import 'package:chapechape_partner/presentation/widgets/messages/message_search_sheet.dart';
import 'custom_sliver_app_bar.dart';

class ScreenAppBars {
  static CustomSliverAppBar getSecurityHistoryAppBar(BuildContext context) {
    return CustomSliverAppBar(
      title: 'Historique de Sécurité',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
          onPressed: () {
            // Rafraîchir les données de sécurité
            // Cette fonctionnalité sera implémentée dans le bloc
          },
        ),
        IconButton(
          icon: const Icon(Icons.help_outline, color: Color(0xFF1A1A1A)),
          onPressed: () {
            // Afficher l'aide sur la sécurité
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Aide - Historique de Sécurité'),
                content: const Text(
                  'Cet écran vous permet de consulter l\'historique de vos activités de sécurité, '
                  'détecter les connexions suspectes et surveiller les modifications sensibles de votre compte.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static CustomSliverAppBar getDashboardAppBar(BuildContext context) {
    return CustomSliverAppBar(
      title: 'Dashboard',
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            int unreadCount = 0;
            if (state is NotificationLoaded) {
              unreadCount = state.totalUnread ?? 0;
            }
            return Stack(
              children: [
                IconButton(
                  icon: SvgPicture.asset(
                    AppIcons.notifications,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1A1A1A), // Strict Black
                      BlendMode.srcATop,
                    ),
                  ),
                  onPressed: () {
                    // Naviguer vers l'écran des notifications
                    context.go('/notifications');
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.refresh,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A), // Strict Black
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            context.read<DashboardBloc>().add(LoadDashboardData());
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.filter,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A), // Strict Black
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Obtenir l'état actuel du dashboard
            final dashboardState = context.read<DashboardBloc>().state;
            
            // Vérifier si l'état est DashboardLoaded
            if (dashboardState is DashboardLoaded) {
              // Afficher la feuille modale du filtre
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: DashboardFilterSheet(
                    currentPeriod: dashboardState.period,
                    startDate: dashboardState.startDate,
                    endDate: dashboardState.endDate,
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  static CustomSliverAppBar getProfileAppBar(BuildContext context) {
    return CustomSliverAppBar(
      title: 'Profil',
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.edit,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            context.go('/profile/edit');
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.settings,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            context.go('/settings');
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.logout,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
        ),
      ],
    );
  }

  static CustomSliverAppBar getResidencesAppBar(BuildContext context) {
    return CustomSliverAppBar(
      title: 'Résidences',
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.search,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Afficher une boîte de dialogue pour la recherche
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Rechercher des résidences'),
                content: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Nom, adresse, ville...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      context.read<ResidenceBloc>().add(SearchResidences(query));
                      Navigator.pop(dialogContext);
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('ANNULER'),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.filter,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Afficher une boîte de dialogue pour les filtres
            showDialog(
              context: context,
              builder: (dialogContext) {
                bool hasPool = false;
                bool isVacationResidence = false;
                bool isSpecialResidence = false;
                String selectedType = 'all';
                double minPrice = 0;
                double maxPrice = 1000000;
                
                return StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: const Text('Filtrer les résidences'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Type de résidence'),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: selectedType,
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('Tous les types'),
                              ),
                              const DropdownMenuItem(
                                value: 'studio_meuble',
                                child: Text('Studio meublé'),
                              ),
                              const DropdownMenuItem(
                                value: 'appartement_meuble',
                                child: Text('Appartement meublé'),
                              ),
                              const DropdownMenuItem(
                                value: 'villa_meublee',
                                child: Text('Villa meublée'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Fourchette de prix'),
                          RangeSlider(
                            values: RangeValues(minPrice, maxPrice),
                            min: 0,
                            max: 1000000,
                            divisions: 100,
                            labels: RangeLabels(
                              '${minPrice.round()} FCFA',
                              '${maxPrice.round()} FCFA',
                            ),
                            onChanged: (values) {
                              setState(() {
                                minPrice = values.start;
                                maxPrice = values.end;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Caractéristiques'),
                          CheckboxListTile(
                            title: const Text('Avec piscine'),
                            value: hasPool,
                            onChanged: (value) {
                              setState(() {
                                hasPool = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Résidence de vacances'),
                            value: isVacationResidence,
                            onChanged: (value) {
                              setState(() {
                                isVacationResidence = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('Résidence spéciale'),
                            value: isSpecialResidence,
                            onChanged: (value) {
                              setState(() {
                                isSpecialResidence = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('ANNULER'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Construire les filtres
                          final filters = <String, dynamic>{};
                          
                          if (selectedType != 'all') {
                            filters['type'] = selectedType;
                          }
                          
                          filters['minPrice'] = minPrice;
                          filters['maxPrice'] = maxPrice;
                          
                          if (hasPool) {
                            filters['hasPool'] = true;
                          }
                          
                          if (isVacationResidence) {
                            filters['isVacationResidence'] = true;
                          }
                          
                          if (isSpecialResidence) {
                            filters['isSpecialResidence'] = true;
                          }
                          
                          context.read<ResidenceBloc>().add(FilterResidences(filters));
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('APPLIQUER'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.sort,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Afficher un menu popup pour les options de tri
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
            final RelativeRect position = RelativeRect.fromRect(
              Rect.fromPoints(
                button.localToGlobal(Offset.zero, ancestor: overlay),
                button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
              ),
              Offset.zero & overlay.size,
            );
            
            showMenu<String>(
              context: context,
              position: position,
              items: [
                const PopupMenuItem<String>(
                  value: 'name_asc',
                  child: Text('Nom (A-Z)'),
                ),
                const PopupMenuItem<String>(
                  value: 'name_desc',
                  child: Text('Nom (Z-A)'),
                ),
                const PopupMenuItem<String>(
                  value: 'price_asc',
                  child: Text('Prix (croissant)'),
                ),
                const PopupMenuItem<String>(
                  value: 'price_desc',
                  child: Text('Prix (décroissant)'),
                ),
                const PopupMenuItem<String>(
                  value: 'surface_asc',
                  child: Text('Surface (croissant)'),
                ),
                const PopupMenuItem<String>(
                  value: 'surface_desc',
                  child: Text('Surface (décroissant)'),
                ),
              ],
            ).then((value) {
              if (value != null) {
                // Extraire le champ de tri et l'ordre
                final parts = value.split('_');
                final field = parts[0];
                final ascending = parts[1] == 'asc';
                
                context.read<ResidenceBloc>().add(SortResidences(field, ascending: ascending));
              }
            });
          },
        ),
      ],
    );
  }

  static CustomSliverAppBar getMessagesAppBar(BuildContext context) {
    return CustomSliverAppBar(
      title: 'Messages',
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.search,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Afficher la feuille modale de recherche de messages
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: const MessageSearchSheet(),
              ),
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.unread,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Filtrer pour n'afficher que les messages non lus
            context.read<MessageBloc>().add(FilterConversations(onlyUnread: true));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Affichage des conversations non lues'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.support,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            context.go('/messages/support');
          },
        ),
      ],
    );
  }

  static CustomSliverAppBar getReservationsAppBar(
    BuildContext context, {
    ReservationBloc? reservationBloc,
    VoidCallback? onCalendarTap,
  }) {
    return CustomSliverAppBar(
      title: 'Réservations',
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.calendar,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            if (onCalendarTap != null) {
              onCalendarTap();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vue calendrier activée')),
              );
            }
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.filter,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Ouvrir le filtre des réservations
            if (reservationBloc != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => _buildReservationFilterSheet(context, reservationBloc),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bloc des réservations non disponible')),
              );
            }
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.sort,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1A1A1A),
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Ouvrir le tri des réservations
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => _buildReservationSortSheet(context, reservationBloc),
            );
          },
        ),
      ],
    );
  }

  // Feuille modale pour le filtre des réservations
  static Widget _buildReservationFilterSheet(BuildContext context, ReservationBloc? reservationBloc) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrer les réservations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Statut'),
          DropdownButtonFormField<String>(
            value: 'all',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tous')),
              DropdownMenuItem(value: 'pending', child: Text('En attente')),
              DropdownMenuItem(value: 'confirmed', child: Text('Confirmée')),
              DropdownMenuItem(value: 'cancelled', child: Text('Annulée')),
              DropdownMenuItem(value: 'completed', child: Text('Terminée')),
            ],
            onChanged: (value) {
              // Appliquer le filtre via le bloc des réservations
              if (reservationBloc != null) {
                reservationBloc.add(FilterReservations(status: value));
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('Période'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date de début',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      // Appliquer le filtre par date de début
                      if (reservationBloc != null) {
                        reservationBloc.add(FilterReservations(startDate: date));
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date de fin',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      // Appliquer le filtre par date de fin
                      if (reservationBloc != null) {
                        reservationBloc.add(FilterReservations(endDate: date));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Appliquer les filtres
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Filtres appliqués')),
                    );
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Feuille modale pour le tri des réservations
  static Widget _buildReservationSortSheet(BuildContext context, ReservationBloc? reservationBloc) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trier les réservations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date de création (plus récent)'),
            leading: Radio<String>(
              value: 'created_desc',
              groupValue: 'created_desc',
              onChanged: (value) {},
            ),
            onTap: () {
              // Appliquer le tri par date de création (plus récent)
              if (reservationBloc != null) {
                reservationBloc.add(SortReservations('created', ascending: false));
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Date de création (plus ancien)'),
            leading: Radio<String>(
              value: 'created_asc',
              groupValue: 'created_desc',
              onChanged: (value) {},
            ),
            onTap: () {
              // Appliquer le tri par date de création (plus ancien)
              if (reservationBloc != null) {
                reservationBloc.add(SortReservations('created', ascending: true));
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Date de réservation (plus récent)'),
            leading: Radio<String>(
              value: 'date_desc',
              groupValue: 'created_desc',
              onChanged: (value) {},
            ),
            onTap: () {
              // Appliquer le tri par date de réservation (plus récent)
              if (reservationBloc != null) {
                reservationBloc.add(SortReservations('date', ascending: false));
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Date de réservation (plus ancien)'),
            leading: Radio<String>(
              value: 'date_asc',
              groupValue: 'created_desc',
              onChanged: (value) {},
            ),
            onTap: () {
              // Appliquer le tri par date de réservation (plus ancien)
              if (reservationBloc != null) {
                reservationBloc.add(SortReservations('date', ascending: true));
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Montant (plus élevé)'),
            leading: Radio<String>(
              value: 'amount_desc',
              groupValue: 'created_desc',
              onChanged: (value) {},
            ),
            onTap: () {
              // Appliquer le tri par montant (plus élevé)
              if (reservationBloc != null) {
                reservationBloc.add(SortReservations('amount', ascending: false));
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Montant (plus bas)'),
            leading: Radio<String>(
              value: 'amount_asc',
              groupValue: 'created_desc',
              onChanged: (value) {},
            ),
            onTap: () {
              // Appliquer le tri par montant (plus bas)
              if (reservationBloc != null) {
                reservationBloc.add(SortReservations('amount', ascending: true));
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;

  const ChatAppBar({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            // TODO: Show thread details
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
