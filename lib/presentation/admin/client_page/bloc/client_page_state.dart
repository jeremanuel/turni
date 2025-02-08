part of 'client_page_bloc.dart';


enum ModalActionState {
  loading,
  confirmed,
  error
}

@freezed
class ClientPageState with _$ClientPageState {
  const factory ClientPageState({
    required Client client,
    
  }) = _ClientPageState;
}
