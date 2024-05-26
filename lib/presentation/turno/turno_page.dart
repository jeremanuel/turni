import 'package:flutter/material.dart';
import '../../domain/entities/session.dart';

class SessionPage extends StatelessWidget {
  final Session session;

  const SessionPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text(session.duration!),
      ),
    );
  }
}
