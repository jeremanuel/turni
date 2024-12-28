import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';
import 'label.dart';
import 'person.dart';

part 'client.freezed.dart';
part 'client.g.dart';

@freezed
class Client with _$Client {

  factory Client({
    @JsonKey(name: "client_id", fromJson: ValueTransformers.fromJsonString, toJson: ValueTransformers.toJsonInt)
    String? clientId,
    @JsonKey(name: "person_id", fromJson: ValueTransformers.fromJsonString)
    String? personId,
    @JsonKey(name: "user_id", fromJson: ValueTransformers.fromJsonString)
    String? userId,
    Person? person

  }) = _Client;
  

  Client._();

  List<Label> get labels {
    
    final randomGenerator = Random();

    List<Label> labelLists = [];

    var options = [
      Label(1, "Crack", Colors.amber), 
      Label(2, "Pro", Colors.blue),
      Label(3, "No paga a tiempo", Colors.red.shade300),
      Label(4, "No contesta el teléfono", Colors.green),
      Label(5, "No guarda Discos", Colors.purple),
      Label(6, "Cliente frecuente", Colors.orange),
      Label(7, "Recomienda a otros", Colors.cyan),
      Label(8, "Siempre puntual", Colors.teal),
      Label(9, "Cliente VIP", Colors.deepOrange),
      Label(10, "Requiere seguimiento", Colors.brown),
      Label(11, "Nuevo", Colors.lime),
      Label(12, "Internacional", Colors.indigo),
      Label(13, "Local", Colors.pink),
      Label(14, "Premium", Colors.deepPurple),
      Label(15, "Estándar", Colors.grey),
    ];

    final array = [
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60),
      randomGenerator.nextInt(60)
    ].forEach((element) {
      if (element < 15) labelLists.add(options[element]);
    });

    return labelLists;
    
  } 

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

  
}

