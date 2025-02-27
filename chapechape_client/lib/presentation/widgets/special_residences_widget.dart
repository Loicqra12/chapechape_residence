import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import 'residence_card.dart';

class SpecialResidencesWidget extends StatelessWidget {
  const SpecialResidencesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ResidencesLoaded) {
          final specialResidences = state.residences
              .where((r) => r.hasPool || r.isVacationResidence)
              .take(5)
              .toList();

          if (specialResidences.isEmpty) {
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
                      'Résidences spéciales',
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
                  itemCount: specialResidences.length,
                  itemBuilder: (context, index) {
                    final residence = specialResidences[index];
                    return SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: ResidenceCard(
                          residence: residence,
                          showBeachBadge: residence.hasPool,
                          showMountainBadge: residence.isVacationResidence,
                          onTap: () {
                            context.read<ResidenceBloc>().add(
                                  LoadDetails(residence.id),
                                );
                            context.goNamed('residence_details', pathParameters: {'id': residence.id});
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
