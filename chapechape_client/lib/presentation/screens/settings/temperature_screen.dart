import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  static const String temperatureUnitKey = 'temperature_unit';
  String _temperatureUnit = 'C'; // Par défaut en Celsius
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferencesService.getInstance();
    setState(() {
      _temperatureUnit = prefs.getString(temperatureUnitKey, defaultValue: 'C');
      _isLoading = false;
    });
  }

  Future<void> _saveTemperatureUnit(String unit) async {
    final prefs = await SharedPreferencesService.getInstance();
    await prefs.setString(temperatureUnitKey, unit);
    setState(() {
      _temperatureUnit = unit;
    });
    
    // Afficher une confirmation
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unité de température modifiée en ${unit == 'C' ? 'Celsius (°C)' : 'Fahrenheit (°F)'}'),
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
                // En-tête explicatif
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Choisissez votre unité de température préférée. Cette unité sera utilisée partout dans l\'application.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
                
                // Carte pour l'unité Celsius
                _buildUnitCard(
                  unit: 'C',
                  title: 'Celsius (°C)',
                  subtitle: 'Utilisé dans la majorité des pays',
                  example: '30°C',
                  icon: Icons.thermostat,
                ),
                
                AppSpacing.verticalSmd,
                
                // Carte pour l'unité Fahrenheit
                _buildUnitCard(
                  unit: 'F',
                  title: 'Fahrenheit (°F)',
                  subtitle: 'Utilisé principalement aux États-Unis',
                  example: '86°F',
                  icon: Icons.thermostat_outlined,
                ),
                
                AppSpacing.verticalLg,
                
                // Exemple de conversion
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
                        Text(
                          'Formule de conversion',
                          style: AppTextStyles.subtitle,
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          '• Celsius à Fahrenheit: °F = (°C × 9/5) + 32\n'
                          '• Fahrenheit à Celsius: °C = (°F - 32) × 5/9',
                          style: AppTextStyles.body,
                        ),
                        AppSpacing.verticalMd,
                        Text(
                          'Exemples:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          '• 0°C = 32°F (Point de congélation de l\'eau)\n'
                          '• 20°C = 68°F (Température ambiante confortable)\n'
                          '• 37°C = 98.6°F (Température corporelle normale)',
                          style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUnitCard({
    required String unit,
    required String title,
    required String subtitle,
    required String example,
    required IconData icon,
  }) {
    final bool isSelected = _temperatureUnit == unit;
    
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
        onTap: () => _saveTemperatureUnit(unit),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
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
                      style: AppTextStyles.body.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                example,
                style: AppTextStyles.subtitle.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
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