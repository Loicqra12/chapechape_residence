import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import 'residence_card.dart';

class FeaturedListings extends StatelessWidget {
  const FeaturedListings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ResidencesLoaded) {
          final featuredResidences = state.residences
              .where((r) => r.isFavorite)
              .take(5)
              .toList();

          if (featuredResidences.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Résidences en vedette',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Naviguer vers la liste complète
                      },
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredResidences.length,
                  itemBuilder: (context, index) {
                    final residence = featuredResidences[index];
                    return SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: ResidenceCard(
                          residence: residence,
                          onTap: () {
                            loadDetails(context, residence.id);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void loadDetails(BuildContext context, String residenceId) {
    context.read<ResidenceBloc>().add(LoadResidenceDetails(residenceId: residenceId));
    context.go('/residence-details/$residenceId');
  }
}
