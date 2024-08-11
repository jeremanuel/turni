import 'package:json_annotation/json_annotation.dart';

part 'range_date.g.dart';

@JsonSerializable()
class RangeDate {
  RangeDate({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  bool isBetween(DateTime date) => date.isAfter(from!) && date.isBefore(to!);

  bool isSameDate(DateTime date) =>
      date.isAtSameMomentAs(from!) || date.isAtSameMomentAs(to!);

  Map<String, dynamic> toJson() => _$RangeDateToJson(this);
  factory RangeDate.fromJson(Map<String, dynamic> json) =>
      _$RangeDateFromJson(json);
}
