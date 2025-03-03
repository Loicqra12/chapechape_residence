import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chapechape_partner/core/constants/app_icons.dart';
import 'package:chapechape_partner/core/constants/app_images.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
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
    this.showLogo = true,
    this.backgroundColor,
    this.expandedHeight,
    this.flexibleSpace,
    this.pinned = true,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: false,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      leading: showLogo ? const ChapeChapeLogo() : null,
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      actions: actions,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
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
