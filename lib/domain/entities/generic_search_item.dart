import 'package:freezed_annotation/freezed_annotation.dart';

import 'client.dart';
import 'session.dart';

part 'generic_search_item.freezed.dart';
part 'generic_search_item.g.dart';

@freezed
class GenericSearchItem with _$GenericSearchItem {


  const factory GenericSearchItem.session(Session session) = GenericSearchSession;

  const factory GenericSearchItem.client(Client client) = GenericSearchClient;

  factory GenericSearchItem.fromJson(Map<String, dynamic> json) => _$GenericSearchItemFromJson(json);
}