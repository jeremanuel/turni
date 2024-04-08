import 'package:freezed_annotation/freezed_annotation.dart';

import 'person.dart';

part 'admin.freezed.dart';
part 'admin.g.dart';

@freezed
class Admin with _$Admin {

  const factory Admin({required Person person}) = _Admin;

  factory Admin.fromJson(Map<String, dynamic> json) => _$AdminFromJson(json);

}