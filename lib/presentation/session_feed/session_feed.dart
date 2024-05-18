import 'package:flutter/material.dart';

import '../../domain/entities/club_type.dart';

class SessionFeedPage extends StatelessWidget {
  const SessionFeedPage({super.key, required this.clubType});

  final ClubType clubType;

  @override
  Widget build(BuildContext context) {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);
    const backgroundColor = Color.fromRGBO(240, 239, 242, 1);

    return Scaffold(
        appBar: AppBar(),
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            clubType.name,
            style: const TextStyle(color: Colors.red),
          ),
        ));
  }
}
