import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/subscription_repository.dart';

part 'client_page_event.dart';
part 'client_page_state.dart';
part 'client_page_bloc.freezed.dart';

class ClientPageBloc extends Bloc<ClientPageEvent, ClientPageState> {

  SubscriptionRepository subscriptionRepository;
  

  ClientPageBloc(Client? client, this.subscriptionRepository) : super(ClientPageState(client: client ?? Client())) {

    on<_SetClient>((event, emit) {
        emit(state.copyWith(
          client: event.client
        ));
    });

    on<_UnSubscribeClient>((event, emit) async {
      final response = await subscriptionRepository.unSubscribeClient(event.clientSubscriptionId, state.client.intClientId);

      final result = response.when(
        left: (failure) => false,
        right: (value) => true,
      );

      if(!result){
        return;
      }

      emit(state.copyWith(
        client: state.client.copyWith(
          clientSubscriptions: state.client.clientSubscriptions!.where((element) => element.clientSubscriptionId != event.clientSubscriptionId).toList()
        )
      ));

    });

    on<_SubscribeClient>((event, emit) async {
      final response = await subscriptionRepository.subscribeClient(event.clientSubscriptionData, state.client.intClientId);

      response.when(
        left: (failure) => failure, 
        right: (newSubscription) {
          emit(
            state.copyWith(
              client: state.client.copyWith(
                clientSubscriptions: [ newSubscription,  ...state.client.clientSubscriptions! ]
              )
            )
          );
        },
      );

    });
  }
}
