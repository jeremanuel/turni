import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:turni/domain/models/turno.dart';

class TurnoPage extends StatelessWidget {
  final Turno turno;
  const TurnoPage({super.key, required this.turno});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
      child: Text(turno.duration),
    ),
    );
  }
}