import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
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
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.pagePadding.copyWith(
                bottom: AppSpacing.pagePadding.bottom + safeBottom + 8,
              ),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Choisissez la langue de l\'application.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                for (var language in _languages) _buildLanguageTile(context, language),
              ],
            ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, Map<String, dynamic> language) {
    final bool isSelected = _selectedLanguage == language['code'];
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        _saveLanguage(language['code']);
      },
      leading: Text(
        language['flag'],
        style: Theme.of(context).textTheme.titleLarge,
      ),
      title: Text(
        language['name'],
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: language['native'] != null
          ? Text(
              language['native'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 22)
          : const Icon(Icons.chevron_right),
    );
  }
} 