import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/models/residence_model.dart';
import 'residence_card.dart';

class NewListingsWidget extends StatelessWidget {
  const NewListingsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ResidencesLoaded) {
          final newResidences = state.residences
              .where((r) => _isNewListing(r))
              .toList();

          if (newResidences.isEmpty) {
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
                      'Nouvelles résidences',
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
                  itemCount: newResidences.length,
                  itemBuilder: (context, index) {
                    final residence = newResidences[index];
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

  bool _isNewListing(Residence residence) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return residence.createdAt != null && residence.createdAt!.isAfter(sevenDaysAgo);
  }
}
