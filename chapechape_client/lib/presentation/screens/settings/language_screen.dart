import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const Color goldColor = Color(0xFFFFD700);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFFE0E0E0);
  
  static const String languageKey = 'app_language';
  
  String _selectedLanguage = 'fr';
  bool _isLoading = true;
  
  // Liste des langues supportées
  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'fr',
      'name': 'Français',
      'flag': '🇫🇷',
      'native': 'Français'
    },
    {
      'code': 'en',
      'name': 'Anglais',
      'flag': '🇬🇧',
      'native': 'English'
    },
    {
      'code': 'es',
      'name': 'Espagnol',
      'flag': '🇪🇸',
      'native': 'Español'
    },
    {
      'code': 'ar',
      'name': 'Arabe',
      'flag': '🇲🇦',
      'native': 'العربية',
      'isRTL': true
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferencesService.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString(languageKey, defaultValue: 'fr');
      _isLoading = false;
    });
  }

  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferencesService.getInstance();
    await prefs.setString(languageKey, languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    if (!mounted) return;
    
    // Trouver le nom de la langue sélectionnée
    final selectedLang = _languages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => {'name': 'Inconnu'},
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Langue changée en ${selectedLang['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Langue'),
        backgroundColor: goldColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.pagePadding,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Choisissez la langue de l\'application.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ),
                
                // Carte d'information sur la langue
                Card(
                  color: greyColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Padding(
                    padding: AppSpacing.pagePadding,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.smd),
                          decoration: BoxDecoration(
                            color: orangeColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: orangeColor,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        const Expanded(
                          child: Text(
                            'Changer la langue modifiera tous les textes dans l\'application, mais nécessitera un redémarrage pour être appliquée complètement.',
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                AppSpacing.verticalLg,
                
                // Liste des langues
                for (var language in _languages)
                  _buildLanguageCard(language),
              ],
            ),
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> language) {
    final bool isSelected = _selectedLanguage == language['code'];
    
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.smd),
      child: Card(
        elevation: isSelected ? 2 : 0,
        color: isSelected ? goldColor.withOpacity(0.2) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: isSelected
              ? const BorderSide(color: goldColor, width: 2)
              : BorderSide(color: greyColor, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _saveLanguage(language['code']),
          child: Padding(
                    padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                // Drapeau
                Text(
                  language['flag'],
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(width: AppSpacing.md),
                
                // Information sur la langue
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language['name'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        language['native'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      if (language['isRTL'] == true)
                        Padding(
                          padding: EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            'Écriture de droite à gauche',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Indicateur de sélection
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: orangeColor,
                    size: 24.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 