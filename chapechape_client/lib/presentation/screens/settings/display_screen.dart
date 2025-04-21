import 'package:flutter/material.dart';
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
              padding: const EdgeInsets.all(16.0),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Personnalisez l\'apparence de l\'application selon vos préférences.',
                    style: TextStyle(fontSize: 16.0, color: Colors.grey),
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
                
                const SizedBox(height: 12.0),
                
                // Option de thème sombre
                _buildThemeCard(
                  theme: 'dark',
                  title: 'Sombre',
                  subtitle: 'Interface sombre pour réduire la fatigue oculaire',
                  icon: Icons.dark_mode,
                ),
                
                const SizedBox(height: 12.0),
                
                // Option de thème du système
                _buildThemeCard(
                  theme: 'system',
                  title: 'Système',
                  subtitle: 'Suit le thème de votre appareil',
                  icon: Icons.settings_brightness,
                ),
                
                const SizedBox(height: 24.0),
                
                // Section Taille du texte
                _buildSectionHeader('Taille du texte'),
                
                Card(
                  color: greyColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.text_fields, color: orangeColor),
                            const SizedBox(width: 16.0),
                            const Expanded(
                              child: Text(
                                'Taille du texte',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
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
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            const Text('A', style: TextStyle(fontSize: 14.0)),
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
                            const Text('A', style: TextStyle(fontSize: 22.0)),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        // Exemple de texte avec la taille sélectionnée
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: greyColor),
                          ),
                          child: Text(
                            'Voici un exemple de texte avec la taille sélectionnée.',
                            style: TextStyle(fontSize: 16.0 * _textSizeScale),
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: blackColor,
        ),
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
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: goldColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _saveTheme(theme),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
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
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14.0,
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