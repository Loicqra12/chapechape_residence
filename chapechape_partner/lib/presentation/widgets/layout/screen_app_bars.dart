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
import 'package:chapechape_partner/presentation/screens/residences/edit_residence_screen.dart';
import 'package:chapechape_partner/presentation/widgets/dashboard/dashboard_filter_sheet.dart';
import 'package:chapechape_partner/presentation/widgets/messages/message_search_sheet.dart';
import 'custom_sliver_app_bar.dart';

class ScreenAppBars {
  static CustomSliverAppBar getDashboardAppBar(BuildContext context) {
    return CustomSliverAppBar(
      title: 'Tableau de bord',
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.notifications,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Naviguer vers l'écran des notifications
            context.go('/notifications');
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.refresh,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
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
              Colors.white,
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
              Colors.white,
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
              Colors.white,
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
              Colors.white,
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
              Colors.white,
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
              Colors.white,
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
            AppIcons.add,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // Utiliser Navigator plutôt que GoRouter pour une meilleure compatibilité avec IndexedStack
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditResidenceScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.sort,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
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
              Colors.white,
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
              Colors.white,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            context.read<MessageBloc>().add(LoadConversations());
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.support,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
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

  static CustomSliverAppBar getReservationsAppBar(BuildContext context) {
    return CustomSliverAppBar(
      title: 'Réservations',
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.calendar,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // TODO: Basculer vers la vue calendrier
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.filter,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // TODO: Ouvrir le filtre des réservations
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            AppIcons.sort,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcATop,
            ),
          ),
          onPressed: () {
            // TODO: Ouvrir le tri des réservations
          },
        ),
      ],
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
