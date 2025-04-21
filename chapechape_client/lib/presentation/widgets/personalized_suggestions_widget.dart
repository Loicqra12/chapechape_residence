import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import 'residence_card.dart';

class PersonalizedSuggestionsWidget extends StatelessWidget {
  const PersonalizedSuggestionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ResidencesLoaded) {
          // TODO: Implémenter la logique de suggestions personnalisées
          final suggestedResidences = state.residences.take(5).toList();

          if (suggestedResidences.isEmpty) {
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
                      'Suggestions pour vous',
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
                  itemCount: suggestedResidences.length,
                  itemBuilder: (context, index) {
                    final residence = suggestedResidences[index];
                    return SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: ResidenceCard(
                          residence: residence,
                          onTap: () {
                            context.read<ResidenceBloc>().add(
                                  LoadResidenceDetails(residenceId: residence.id),
                                );
                            context.go('/residence-details/${residence.id}');
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
}
