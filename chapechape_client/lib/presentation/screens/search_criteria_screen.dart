import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/advanced_search_widget.dart';

/// Écran des critères de recherche (style Airbnb).
/// Affiche le formulaire avancé ; au "Rechercher", envoie les paramètres vers /search.
class SearchCriteriaScreen extends StatelessWidget {
  const SearchCriteriaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? null : AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Recherche',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: AdvancedSearchWidget(
          onSearch: (params) {
            context.pop();
            context.push('/search', extra: params);
          },
        ),
      ),
    );
  }
}
