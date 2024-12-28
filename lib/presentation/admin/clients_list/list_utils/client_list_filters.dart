import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_list_filters.freezed.dart';
part 'client_list_filters.g.dart';

@freezed
class ClientListFilters with _$ClientListFilters {



  factory ClientListFilters({@Default("") String? search, int? statusId, int? labelId}) = _ClientListFilters;

  factory ClientListFilters.fromJson(Map<String, dynamic> json) => _$ClientListFiltersFromJson(json);

}



