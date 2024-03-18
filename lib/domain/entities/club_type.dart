
import 'package:freezed_annotation/freezed_annotation.dart';

part 'club_type.freezed.dart';
part 'club_type.g.dart';

@freezed
class ClubType with _$ClubType {
  factory ClubType({
    required int club_type_id, 
    required String name
  }) = _ClubType;
	
  factory ClubType.fromJson(Map<String, dynamic> json) =>
			_$ClubTypeFromJson(json);
}
