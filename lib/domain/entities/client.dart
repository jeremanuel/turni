
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';
import 'label.dart';
import 'person.dart';
import 'subscription/client_subscription.dart';

part 'client.freezed.dart';
part 'client.g.dart';

@freezed
sealed class Client with _$Client {

  factory Client({
    @JsonKey(name: "client_id", fromJson: ValueTransformers.fromJsonString, toJson: ValueTransformers.toJsonInt)
    String? clientId,
    @JsonKey(name: "person_id", fromJson: ValueTransformers.fromJsonString)
    String? personId,

    @JsonKey(name: "user_id", fromJson: ValueTransformers.fromJsonString)
    String? userId,
    @JsonKey(name: "club_id", fromJson: ValueTransformers.fromJsonInt)
    int? clubId,
    Person? person,
    @JsonKey(name: "client_label", fromJson: Label.clientLabelToLabel)
    List<Label>? labels,
    @JsonKey(name: "client_subscription")
    List<ClientSubscription>? clientSubscriptions

  }) = _Client;
  

  Client._();

  int get intClientId => int.parse(clientId!);

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

  
}

