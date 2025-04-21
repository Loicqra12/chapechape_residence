import 'package:flutter/material.dart';
import '../../core/services/currency_service.dart';

class CurrencySelectorWidget extends StatefulWidget {
  final void Function(String)? onCurrencyChanged;
  
  const CurrencySelectorWidget({
    Key? key,
    this.onCurrencyChanged,
  }) : super(key: key);

  @override
  State<CurrencySelectorWidget> createState() => _CurrencySelectorWidgetState();
}

class _CurrencySelectorWidgetState extends State<CurrencySelectorWidget> {
  final CurrencyService _currencyService = CurrencyService();
  String _selectedCurrency = CurrencyService.defaultCurrency;

  @override
  void initState() {
    super.initState();
    _loadCurrentCurrency();
  }

  Future<void> _loadCurrentCurrency() async {
    await _currencyService.loadPreferredCurrency();
    setState(() {
      _selectedCurrency = _currencyService.currentCurrency;
    });
  }

  Future<void> _changeCurrency(String currency) async {
    final success = await _currencyService.setPreferredCurrency(currency);
    if (success) {
      setState(() {
        _selectedCurrency = currency;
      });
      
      if (widget.onCurrencyChanged != null) {
        widget.onCurrencyChanged!(currency);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedCurrency,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      underline: Container(
        height: 2,
        color: Theme.of(context).primaryColor,
      ),
      onChanged: (String? newValue) {
        if (newValue != null) {
          _changeCurrency(newValue);
        }
      },
      items: CurrencyService.availableCurrencies
          .map<DropdownMenuItem<String>>((String currency) {
        IconData? icon;
        switch (currency) {
          case 'EUR':
            icon = Icons.euro;
            break;
          case 'USD':
            icon = Icons.attach_money;
            break;
          case 'GBP':
            icon = Icons.currency_pound;
            break;
          default:
            icon = Icons.monetization_on;
        }
        
        return DropdownMenuItem<String>(
          value: currency,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(currency),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Widget plus compact pour afficher dans l'app bar
class CurrencySelectorIcon extends StatelessWidget {
  final VoidCallback onTap;
  
  const CurrencySelectorIcon({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.currency_exchange),
      tooltip: 'Changer de devise',
      onPressed: onTap,
    );
  }
}

// Bottom sheet pour sélectionner la devise
class CurrencySelectorBottomSheet extends StatelessWidget {
  final void Function(String)? onCurrencyChanged;
  
  const CurrencySelectorBottomSheet({
    Key? key,
    this.onCurrencyChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CurrencyService currencyService = CurrencyService();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisir une devise',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...CurrencyService.availableCurrencies.map((currency) {
            IconData? icon;
            switch (currency) {
              case 'EUR':
                icon = Icons.euro;
                break;
              case 'USD':
                icon = Icons.attach_money;
                break;
              case 'GBP':
                icon = Icons.currency_pound;
                break;
              default:
                icon = Icons.monetization_on;
            }
            
            return ListTile(
              leading: Icon(icon),
              title: Text(currency),
              selected: currency == currencyService.currentCurrency,
              onTap: () async {
                await currencyService.setPreferredCurrency(currency);
                if (onCurrencyChanged != null) {
                  onCurrencyChanged!(currency);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
} 