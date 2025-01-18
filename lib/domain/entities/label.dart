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
  ) = _Label;

  factory Label.fromJson(Map<String, dynamic> json) => _$LabelFromJson(json);

  static List<Label> clientLabelToLabel(List? clientLabels){

    if(clientLabels == null) return [];

    return (clientLabels.map((el) => Label.fromJson(el['label'])).toList());

  }

}