import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/models/country.dart';

class CountryFlagWidget extends StatelessWidget {
  final String countryCode;
  final double size;
  final bool showName;
  final String? countryName;
  final VoidCallback? onTap;
  final bool showDropdownIndicator;
  final bool isSelected;
  final EdgeInsetsGeometry padding;

  const CountryFlagWidget({
    Key? key,
    required this.countryCode,
    this.size = 24,
    this.showName = false,
    this.countryName,
    this.onTap,
    this.showDropdownIndicator = false,
    this.isSelected = false,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String flagPath = _getFlagPath(countryCode);
    final String name = countryName ?? _getCountryName(countryCode);

    final Widget flag = ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: flagPath.endsWith('.svg')
            ? SvgPicture.asset(
                flagPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : Image.asset(
                flagPath,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
      ),
    );

    Widget result = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        flag,
        if (showName) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (showDropdownIndicator) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: size * 0.75,
            color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ],
      ],
    );

    if (padding != EdgeInsets.zero) {
      result = Padding(padding: padding, child: result);
    }

    if (onTap != null) {
      result = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: result,
      );
    }

    return result;
  }

  String _getFlagPath(String countryCode) {
    // Mapper les codes de pays aux chemins des drapeaux
    final Map<String, String> flagPaths = {
      'ci': 'assets/images/flags/cote-divoire.png',
      'sn': 'assets/images/flags/senegal.png',
      'gh': 'assets/images/flags/ghana (1).png',
      'ng': 'assets/images/flags/nigeria.png',
      'bj': 'assets/images/flags/benin.png',
      'bf': 'assets/images/flags/burkina-faso.svg',
      'cv': 'assets/images/flags/cape-verde.svg',
      'gm': 'assets/images/flags/gambia.svg',
      'gn': 'assets/images/flags/guinea.svg',
      'lr': 'assets/images/flags/liberia.png',
      'ml': 'assets/images/flags/mali.png',
      'ne': 'assets/images/flags/niger.svg',
      'sl': 'assets/images/flags/sierra-leone.svg',
      'tg': 'assets/images/flags/togo.png',
      // Pays supplémentaires d'Afrique
      'za': 'assets/images/flags/south-africa.png',
      'ma': 'assets/images/flags/morocco.png',
      'eg': 'assets/images/flags/egypt.png',
      'dz': 'assets/images/flags/algeria.png',
      'tn': 'assets/images/flags/tunisia.png',
      // Ajouter d'autres pays au besoin
    };

    // Retourner le chemin du drapeau ou un drapeau par défaut
    return flagPaths[countryCode.toLowerCase()] ?? 'assets/images/flags/flag.png';
  }

  String _getCountryName(String countryCode) {
    // Mapper les codes de pays aux noms de pays en français
    final Map<String, String> countryNames = {
      'ci': 'Côte d\'Ivoire',
      'sn': 'Sénégal',
      'gh': 'Ghana',
      'ng': 'Nigeria',
      'bj': 'Bénin',
      'bf': 'Burkina Faso',
      'cv': 'Cap-Vert',
      'gm': 'Gambie',
      'gn': 'Guinée',
      'lr': 'Liberia',
      'ml': 'Mali',
      'ne': 'Niger',
      'sl': 'Sierra Leone',
      'tg': 'Togo',
      // Pays supplémentaires d'Afrique
      'za': 'Afrique du Sud',
      'ma': 'Maroc',
      'eg': 'Égypte',
      'dz': 'Algérie',
      'tn': 'Tunisie',
      // Ajouter d'autres pays au besoin
    };

    // Retourner le nom du pays ou le code de pays en majuscules
    return countryNames[countryCode.toLowerCase()] ?? countryCode.toUpperCase();
  }
  
  // Méthode pratique pour créer un widget à partir d'un objet Country
  static CountryFlagWidget fromCountry({
    required Country country,
    double size = 24,
    bool showName = false,
    VoidCallback? onTap,
    bool showDropdownIndicator = false,
    bool isSelected = false,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return CountryFlagWidget(
      countryCode: country.code,
      countryName: country.name,
      size: size,
      showName: showName,
      onTap: onTap,
      showDropdownIndicator: showDropdownIndicator,
      isSelected: isSelected,
      padding: padding,
    );
  }
}
