import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';
import 'person.dart';

part 'client.freezed.dart';
part 'client.g.dart';

@freezed
class Client with _$Client {

  factory Client({
    @JsonKey(name: "client_id", fromJson: ValueTransformers.fromJsonString, toJson: ValueTransformers.toJsonInt)
    String? clientId,
    @JsonKey(name: "person_id", fromJson: ValueTransformers.fromJsonString)
    String? personId,
    @JsonKey(name: "user_id", fromJson: ValueTransformers.fromJsonString)
    String? userId,
    Person? person

  }) = _Client;
  


  
  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

  
}

