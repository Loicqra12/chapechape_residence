import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class Country {
  final String code;
  final String name;
  final String flagEmoji;
  final List<String> cities;

  const Country({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.cities,
  });
}

class LocationSelectorWidget extends StatefulWidget {
  final Function(String, String?)? onLocationSelected;
  final String? initialCountryCode;
  final String? initialCity;

  const LocationSelectorWidget({
    Key? key,
    this.onLocationSelected,
    this.initialCountryCode,
    this.initialCity,
  }) : super(key: key);

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  late String _selectedCountryCode;
  String? _selectedCity;

  // Liste des pays d'Afrique de l'Ouest avec leurs villes principales
  final List<Country> _countries = [
    const Country(
      code: 'CI',
      name: 'Côte d\'Ivoire',
      flagEmoji: '🇨🇮',
      cities: [
        'Abidjan',
        'Yamoussoukro',
        'Bouaké',
        'San Pedro',
        'Korhogo',
        'Daloa',
        'Homme',
        'Gagnoa',
        'Abengourou',
        'Anyama',
      ],
    ),
    const Country(
      code: 'SN',
      name: 'Sénégal',
      flagEmoji: '🇸🇳',
      cities: ['Dakar', 'Thiès', 'Rufisque', 'Kaolack', 'Saint-Louis'],
    ),
    const Country(
      code: 'ML',
      name: 'Mali',
      flagEmoji: '🇲🇱',
      cities: ['Bamako', 'Sikasso', 'Mopti', 'Ségou', 'Kayes'],
    ),
    const Country(
      code: 'BF',
      name: 'Burkina Faso',
      flagEmoji: '🇧🇫',
      cities: ['Ouagadougou', 'Bobo-Dioulasso', 'Koudougou', 'Banfora'],
    ),
    const Country(
      code: 'GH',
      name: 'Ghana',
      flagEmoji: '🇬🇭',
      cities: ['Accra', 'Kumasi', 'Tamale', 'Sekondi-Takoradi', 'Cape Coast'],
    ),
    const Country(
      code: 'TG',
      name: 'Togo',
      flagEmoji: '🇹🇬',
      cities: ['Lomé', 'Sokodé', 'Kara', 'Kpalimé', 'Atakpamé'],
    ),
    const Country(
      code: 'BJ',
      name: 'Bénin',
      flagEmoji: '🇧🇯',
      cities: ['Cotonou', 'Porto-Novo', 'Parakou', 'Djougou', 'Bohicon'],
    ),
    const Country(
      code: 'GN',
      name: 'Guinée',
      flagEmoji: '🇬🇳',
      cities: ['Conakry', 'Nzérékoré', 'Kankan', 'Kindia', 'Labé'],
    ),
    const Country(
      code: 'NE',
      name: 'Niger',
      flagEmoji: '🇳🇪',
      cities: ['Niamey', 'Zinder', 'Maradi', 'Agadez', 'Tahoua'],
    ),
    const Country(
      code: 'NG',
      name: 'Nigéria',
      flagEmoji: '🇳🇬',
      cities: ['Lagos', 'Abuja', 'Kano', 'Ibadan', 'Port Harcourt'],
    ),
    const Country(
      code: 'LR',
      name: 'Libéria',
      flagEmoji: '🇱🇷',
      cities: ['Monrovia', 'Gbarnga', 'Kakata', 'Bensonville', 'Harper'],
    ),
    const Country(
      code: 'SL',
      name: 'Sierra Leone',
      flagEmoji: '🇸🇱',
      cities: ['Freetown', 'Bo', 'Kenema', 'Makeni', 'Koidu'],
    ),
    const Country(
      code: 'GM',
      name: 'Gambie',
      flagEmoji: '🇬🇲',
      cities: ['Banjul', 'Serekunda', 'Brikama', 'Bakau', 'Farafenni'],
    ),
    const Country(
      code: 'CV',
      name: 'Cap Vert',
      flagEmoji: '🇨🇻',
      cities: ['Praia', 'Mindelo', 'Santa Maria', 'Assomada', 'Tarrafal'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = widget.initialCountryCode ?? 'CI';
    _selectedCity = widget.initialCity;
  }

  Country _getSelectedCountry() {
    return _countries.firstWhere(
      (country) => country.code == _selectedCountryCode,
      orElse: () => _countries.first,
    );
  }

  void _selectCountry(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
      _selectedCity = null;
    });

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(countryCode, null);
    }
  }

  void _selectCity(String city) {
    setState(() {
      _selectedCity = city;
    });

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(_selectedCountryCode, city);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = _getSelectedCountry();

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCountry.flagEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            onSelected: _selectCountry,
            itemBuilder: (BuildContext context) {
              return _countries.map((country) {
                return PopupMenuItem<String>(
                  value: country.code,
                  child: Row(
                    children: [
                      Text(
                        country.flagEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(country.name),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCity ?? 'Toutes les villes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            onSelected: _selectCity,
            itemBuilder: (BuildContext context) {
              final cities = selectedCountry.cities;
              return [
                const PopupMenuItem<String>(
                  value: '',
                  child: Text('Toutes les villes'),
                ),
                ...cities.map((city) {
                  return PopupMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
              ];
            },
          ),
        ],
      ),
    );
  }
}
