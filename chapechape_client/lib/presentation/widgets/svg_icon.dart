import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String assetName;
  final double width;
  final double height;
  final Color? color;

  const SvgIcon({
    Key? key,
    required this.assetName,
    this.width = 24,
    this.height = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: width,
      height: height,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}

// Widget pour les drapeaux
class CountryFlag extends StatelessWidget {
  final String countryCode;
  final double width;
  final double height;

  const CountryFlag({
    Key? key,
    required this.countryCode,
    this.width = 32,
    this.height = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/flags/$countryCode.svg',
      width: width,
      height: height,
    );
  }
}

// Widget pour les icônes d'équipements
class AmenityIcon extends StatelessWidget {
  final String amenityName;
  final double size;
  final Color? color;

  const AmenityIcon({
    Key? key,
    required this.amenityName,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgIcon(
      assetName: 'assets/icons/amenities/$amenityName.svg',
      width: size,
      height: size,
      color: color,
    );
  }
}

// Widget pour les icônes de catégories
class CategoryIcon extends StatelessWidget {
  final String categoryName;
  final double size;
  final Color? color;

  const CategoryIcon({
    Key? key,
    required this.categoryName,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgIcon(
      assetName: 'assets/icons/categories/$categoryName.svg',
      width: size,
      height: size,
      color: color,
    );
  }
}
