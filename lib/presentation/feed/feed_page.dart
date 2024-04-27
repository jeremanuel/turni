
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/feed/cubit/feed/feed_cubit.dart';
import 'package:turni/presentation/feed/widgets/turno_card.dart';

import 'testin.dart';

class FeedPage extends StatelessWidget {
  late final FeedCubit feedCubit;

  FeedPage({super.key}) {
    feedCubit = sl<FeedCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Testin();
    return BlocBuilder<FeedCubit, FeedState>(
      bloc: feedCubit,
      builder: (context, state) {

        if(state.isLoading){
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemBuilder: (context, index) => SessionCard(session: state.turnos[index]),
                    itemCount: state.turnos.length            
                  ),
                ),
          builder: (context, value, child) {
            return Opacity(
              opacity:value,
              child: Transform.translate(
                offset: Offset(0, value * -50 + 50),
                child: child,
              ),
            );
          }
        );
      },
    );
  }


}
