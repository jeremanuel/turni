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
    
    int r = (color.r * 255).round();
    int g = (color.g * 255).round();
    int b = (color.b * 255).round();
    int a = (color.a * 255).round();

    return '#${a.toRadixString(16).padLeft(2, '0')}${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }
}
