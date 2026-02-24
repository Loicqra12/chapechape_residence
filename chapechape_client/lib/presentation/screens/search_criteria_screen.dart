import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/advanced_search_widget.dart';

/// Écran des critères de recherche (style Airbnb).
/// Affiche le formulaire avancé ; au "Rechercher", envoie les paramètres vers /search.
class SearchCriteriaScreen extends StatelessWidget {
  const SearchCriteriaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A1A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Recherche',
          style: TextStyle(
            color: const Color(0xFF1A1A1A),
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
