import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_state.dart';
import '../../core/blocs/residence/residence_event.dart';
import '../../core/models/residence_model.dart';
import 'residence_card.dart';

class VacationResidencesWidget extends StatelessWidget {
  const VacationResidencesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ResidencesLoaded) {
          final vacationResidences = state.residences
              .where((r) => r.isVacationResidence)
              .take(5)
              .toList();

          if (vacationResidences.isEmpty) {
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
                      'Résidences de vacances',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        context.goNamed('vacation_residences');
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
                  itemCount: vacationResidences.length,
                  itemBuilder: (context, index) {
                    final residence = vacationResidences[index];
                    return SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: ResidenceCard(
                          residence: residence,
                          showBeachBadge: true,
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
