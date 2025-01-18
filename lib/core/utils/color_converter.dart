import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class ColorConverter implements JsonConverter<Color?, String?> {
  const ColorConverter();

  @override
  Color? fromJson(String? hexCode) {

    if(hexCode == null) return null;
    
    // Si el código de color tiene el prefijo "#", lo eliminamos
    hexCode = hexCode.replaceAll('#', '');

    // Convertimos el código hexadecimal en un valor entero
    int colorInt = int.parse(hexCode, radix: 16);

    // Si el código tiene 6 caracteres, agregamos la opacidad máxima (FF) al principio
    if (hexCode.length == 6) {
      colorInt = 0xFF000000 | colorInt;
    }

    return Color(colorInt);
  }

  @override
  String? toJson(Color? color) {
    if(color == null) return null;

    return "${color.r},${color.g},${color.b},${color.a}";
  }
}
