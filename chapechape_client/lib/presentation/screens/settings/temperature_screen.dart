import 'package:flutter/material.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  static const Color goldColor = Color(0xFFFFD700);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFFE0E0E0);
  
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Température'),
        backgroundColor: goldColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // En-tête explicatif
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Choisissez votre unité de température préférée. Cette unité sera utilisée partout dans l\'application.',
                    style: TextStyle(fontSize: 16.0, color: Colors.grey),
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
                
                const SizedBox(height: 12.0),
                
                // Carte pour l'unité Fahrenheit
                _buildUnitCard(
                  unit: 'F',
                  title: 'Fahrenheit (°F)',
                  subtitle: 'Utilisé principalement aux États-Unis',
                  example: '86°F',
                  icon: Icons.thermostat_outlined,
                ),
                
                const SizedBox(height: 24.0),
                
                // Exemple de conversion
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
                        const Text(
                          'Formule de conversion',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        const Text(
                          '• Celsius à Fahrenheit: °F = (°C × 9/5) + 32\n'
                          '• Fahrenheit à Celsius: °C = (°F - 32) × 5/9',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'Exemples:',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '• 0°C = 32°F (Point de congélation de l\'eau)\n'
                          '• 20°C = 68°F (Température ambiante confortable)\n'
                          '• 37°C = 98.6°F (Température corporelle normale)',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
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
      color: isSelected ? goldColor.withOpacity(0.2) : greyColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: goldColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _saveTemperatureUnit(unit),
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
              Text(
                example,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: isSelected ? orangeColor : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8.0),
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