import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/color_converter.dart';

part 'label.freezed.dart';
part 'label.g.dart';

@freezed
class Label with _$Label {

  factory Label(int labelId, String value, @ColorConverter() Color? color) = _Label;

  factory Label.fromJson(Map<String, dynamic> json) => _$LabelFromJson(json);

}