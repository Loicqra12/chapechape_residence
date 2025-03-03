import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_partner/core/constants/app_icons.dart';
import 'package:chapechape_partner/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_partner/core/blocs/dashboard/dashboard_bloc.dart';
import 'package:chapechape_partner/core/blocs/residence/residence_bloc.dart';
import 'package:chapechape_partner/core/blocs/message/message_bloc.dart';
import 'package:chapechape_partner/core/blocs/reservation/reservation_bloc.dart';
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
            // TODO: Ouvrir les notifications
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
            // TODO: Ouvrir le filtre du tableau de bord
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
            // TODO: Ouvrir la recherche de résidences
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
            // TODO: Ouvrir le filtre des résidences
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
            context.go('/residences/add');
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
            // TODO: Ouvrir le tri des résidences
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
            // TODO: Ouvrir la recherche de messages
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
            context.read<MessageBloc>().add(LoadMessages(userId: 'unread', refresh: true));
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
