import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class ColorConverter implements JsonConverter<Color?, String?> {
  const ColorConverter();

  @override
  Color? fromJson(String? json) {
    if(json == null || json.isEmpty) return null;

    final valuesList = json.split(",").map((e) => int.parse(e)).toList();

    return Color.fromRGBO(valuesList[0], valuesList[1],valuesList[2], valuesList[3].toDouble());
  }

  @override
  String? toJson(Color? color) {
    if(color == null) return null;

    return "${color.r},${color.g},${color.b},${color.a}";
  }
}
