import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chapechape_partner/core/constants/app_icons.dart';
import 'package:chapechape_partner/core/constants/app_images.dart';
import 'package:chapechape_partner/core/theme/colors.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;
  final Color? backgroundColor;
  final double? expandedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final PreferredSizeWidget? bottom;

  const CustomSliverAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showLogo = true,
    this.backgroundColor,
    this.expandedHeight,
    this.flexibleSpace,
    this.pinned = true,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? Theme.of(context).colorScheme.surface;
    const double titleFontSize = 20.0; // Taille fixe pour tous les titres (Dashboard, Réservations, Résidences)
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: false,
      backgroundColor: bgColor,
      surfaceTintColor: bgColor,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      leading: leading ?? (showLogo ? const ChapeChapeLogo() : null),
      iconTheme: IconThemeData(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.textPrimary,
      ),
      actionsIconTheme: IconThemeData(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.textPrimary,
      ),
      centerTitle: false,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                fontSize: titleFontSize,
              ),
        ),
      ),
      actions: actions,
      flexibleSpace: flexibleSpace,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: bottom!.preferredSize,
              child: Column(
                children: [
                  bottom!,
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.05),
                          Colors.grey.withOpacity(0.1),
                          Colors.grey.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.05),
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class ChapeChapeLogo extends StatelessWidget {
  const ChapeChapeLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(AppImages.getLogo(isDarkMode: isDark)),
    );
  }
}
