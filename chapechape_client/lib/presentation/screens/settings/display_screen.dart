import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  static const Color goldColor = Color(0xFFFFD700);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFFE0E0E0);
  
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Affichage'),
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
                    'Personnalisez l\'apparence de l\'application selon vos préférences.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
                  color: greyColor.withOpacity(0.3),
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
                            const Icon(Icons.text_fields, color: orangeColor),
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
                                color: orangeColor,
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
                                activeColor: orangeColor,
                                inactiveColor: greyColor,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(color: greyColor),
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
        style: AppTextStyles.subtitle.copyWith(color: blackColor),
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
      color: isSelected ? goldColor.withOpacity(0.2) : greyColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: isSelected
            ? const BorderSide(color: goldColor, width: 2)
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
                  color: isSelected ? goldColor : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : orangeColor,
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
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
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
    );
  }
} 