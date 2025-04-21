import 'package:flutter/material.dart';
import '../../core/services/currency_service.dart';

/// Widget permettant à l'utilisateur de sélectionner une devise
class CurrencySelectorWidget extends StatefulWidget {
  /// Fonction à appeler lorsque la devise est modifiée
  final Function(String)? onCurrencyChanged;
  
  const CurrencySelectorWidget({
    Key? key,
    this.onCurrencyChanged,
  }) : super(key: key);

  @override
  State<CurrencySelectorWidget> createState() => _CurrencySelectorWidgetState();
}

class _CurrencySelectorWidgetState extends State<CurrencySelectorWidget> {
  final CurrencyService _currencyService = CurrencyService();
  String _selectedCurrency = 'FCFA';
  
  @override
  void initState() {
    super.initState();
    _loadCurrentCurrency();
  }
  
  /// Charge la devise actuelle depuis le service
  Future<void> _loadCurrentCurrency() async {
    final currency = _currencyService.currentCurrency;
    if (mounted) {
      setState(() {
        _selectedCurrency = currency;
      });
    }
  }
  
  /// Change la devise sélectionnée
  Future<void> _changeCurrency(String newCurrency) async {
    await _currencyService.setPreferredCurrency(newCurrency);
    if (mounted) {
      setState(() {
        _selectedCurrency = newCurrency;
      });
      
      // Notifier le parent du changement
      if (widget.onCurrencyChanged != null) {
        widget.onCurrencyChanged!(newCurrency);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedCurrency,
      underline: Container(),
      icon: const Icon(Icons.currency_exchange, size: 20),
      items: _currencyService.availableCurrencies.map((String currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          _changeCurrency(newValue);
        }
      },
    );
  }
}

/// Icône de sélection de devise pour la barre d'application
class CurrencySelectorIcon extends StatelessWidget {
  final Function(String)? onCurrencyChanged;
  
  const CurrencySelectorIcon({
    Key? key,
    this.onCurrencyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.currency_exchange),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return CurrencySelectorBottomSheet(
              onCurrencyChanged: onCurrencyChanged,
            );
          },
        );
      },
      tooltip: 'Changer de devise',
    );
  }
}

/// BottomSheet pour sélectionner la devise
class CurrencySelectorBottomSheet extends StatelessWidget {
  final CurrencyService _currencyService = CurrencyService();
  final Function(String)? onCurrencyChanged;
  
  CurrencySelectorBottomSheet({
    Key? key,
    this.onCurrencyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Sélectionner une devise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...buildCurrencyList(context),
        ],
      ),
    );
  }
  
  List<Widget> buildCurrencyList(BuildContext context) {
    final Map<String, IconData> currencyIcons = {
      'FCFA': Icons.attach_money,
      'EUR': Icons.euro,
      'USD': Icons.attach_money,
      'GBP': Icons.currency_pound,
    };
    
    return _currencyService.availableCurrencies.map((currency) {
      return ListTile(
        leading: Icon(currencyIcons[currency] ?? Icons.attach_money),
        title: Text(currency),
        onTap: () async {
          await _currencyService.setPreferredCurrency(currency);
          if (onCurrencyChanged != null) {
            onCurrencyChanged!(currency);
          }
          Navigator.pop(context);
        },
      );
    }).toList();
  }
} 