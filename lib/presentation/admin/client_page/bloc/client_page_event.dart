part of 'client_page_bloc.dart';

@freezed
class ClientPageEvent with _$ClientPageEvent {
  const factory ClientPageEvent.setClient(Client client) = _SetClient;
  const factory ClientPageEvent.unSubscribeClient(int clientSubscriptionId) = _UnSubscribeClient;
  const factory ClientPageEvent.subscribeClient(Map<String, dynamic> clientSubscriptionData) = _SubscribeClient;
  const factory ClientPageEvent.addPayment(Map<String, dynamic> paymentData) = _AddPayment;



}