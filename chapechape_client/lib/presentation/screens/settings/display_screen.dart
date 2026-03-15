import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/blocs/theme/theme_cubit.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  static const String themeKey = 'app_theme';
  static const String textSizeKey = 'text_size';
  
  String _selectedTheme = 'light';
  double _textSizeScale = 1.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferencesService.getInstance();
    setState(() {
      _selectedTheme = prefs.getString(themeKey, defaultValue: 'light');
      _textSizeScale = prefs.getDouble(textSizeKey, defaultValue: 1.0);
      _isLoading = false;
    });
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferencesService.getInstance();
    await prefs.setString(themeKey, theme);
    setState(() {
      _selectedTheme = theme;
    });
    // Appliquer le thème immédiatement dans toute l'app
    if (mounted) {
      final themeMode = theme == 'light'
          ? ThemeMode.light
          : theme == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
      context.read<ThemeCubit>().setTheme(themeMode);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thème changé en ${theme == 'light' ? 'Clair' : theme == 'dark' ? 'Sombre' : 'Système'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveTextSize(double size) async {
    final prefs = await SharedPreferencesService.getInstance();
    await prefs.setDouble(textSizeKey, size);
    setState(() {
      _textSizeScale = size;
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Taille du texte modifiée'),
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
                    'Personnalisez l\'apparence de l\'application selon vos préférences.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ),
                
                // Section Thème
                _buildSectionHeader('Thème'),
                
                // Option de thème clair
                _buildThemeCard(
                  theme: 'light',
                  title: 'Clair',
                  subtitle: 'Interface lumineuse avec fond blanc',
                  icon: Icons.light_mode,
                ),
                
                AppSpacing.verticalSmd,
                
                // Option de thème sombre
                _buildThemeCard(
                  theme: 'dark',
                  title: 'Sombre',
                  subtitle: 'Interface sombre pour réduire la fatigue oculaire',
                  icon: Icons.dark_mode,
                ),
                
                AppSpacing.verticalSmd,
                
                // Option de thème du système
                _buildThemeCard(
                  theme: 'system',
                  title: 'Système',
                  subtitle: 'Suit le thème de votre appareil',
                  icon: Icons.settings_brightness,
                ),
                
                AppSpacing.verticalLg,
                
                // Section Taille du texte
                _buildSectionHeader('Taille du texte'),
                
                Card(
                  color: AppTheme.dividerColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.text_fields, color: AppTheme.primaryColor),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Taille du texte',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${(_textSizeScale * 100).toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalMd,
                        Row(
                          children: [
                            Text('A', style: AppTextStyles.body),
                            Expanded(
                              child: Slider(
                                value: _textSizeScale,
                                min: 0.8,
                                max: 1.4,
                                divisions: 6,
                                activeColor: AppTheme.primaryColor,
                                inactiveColor: AppTheme.dividerColor,
                                onChanged: (value) {
                                  setState(() {
                                    _textSizeScale = value;
                                  });
                                },
                                onChangeEnd: (value) {
                                  _saveTextSize(value);
                                },
                              ),
                            ),
                            Text('A', style: AppTextStyles.title),
                          ],
                        ),
                        AppSpacing.verticalMd,
                        // Exemple de texte avec la taille sélectionnée
                        Container(
                          padding: EdgeInsets.all(AppSpacing.smd),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Text(
                            'Voici un exemple de texte avec la taille sélectionnée.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16.0 * _textSizeScale,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.smd),
      child: Text(
        title,
        style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildThemeCard({
    required String theme,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selectedTheme == theme;
    
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.dividerColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: isSelected
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => _saveTheme(theme),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppTheme.textLight : AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24.0,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 