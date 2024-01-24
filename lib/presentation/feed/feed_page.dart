
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/feed/cubit/feed/feed_cubit.dart';
import 'package:turni/presentation/feed/widgets/turno_card.dart';

class FeedPage extends StatelessWidget {
  late final FeedCubit feedCubit;

  FeedPage({super.key}) {
    feedCubit = sl<FeedCubit>();
  }

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<FeedCubit, FeedState>(
      bloc: feedCubit,
      builder: (context, state) {

        if(state.isLoading){
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemBuilder: (context, index) => TurnoCard(turno: state.turnos[index]),
            itemCount: state.turnos.length            
          ),
        );
      },
    );
  }


}
