import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/color_converter.dart';

part 'label.freezed.dart';
part 'label.g.dart';

@freezed
class Label with _$Label {

  factory Label(
    @JsonKey(name: "label_id")
    int? labelId, 
    @JsonKey(name: "name")
    String value, 
    @ColorConverter() 
    @JsonKey(name: "color_hex_code")
    Color? color,
    @JsonKey(name: "club_id")
    int clubId
  ) = _Label;

  factory Label.fromJson(Map<String, dynamic> json) => _$LabelFromJson(json);

  static List<Label> clientLabelToLabel(List? clientLabels){

    if(clientLabels == null) return [];

    return (clientLabels.map((el) => Label.fromJson(el['label'])).toList());

  }

  static String toJsonColor(Color color){
      int r = (color.r * 255).round();
      int g = (color.g * 255).round();
      int b = (color.b * 255).round();
      int a = (color.a * 255).round();

    return '#${a.toRadixString(16).padLeft(2, '0')}${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  }

}