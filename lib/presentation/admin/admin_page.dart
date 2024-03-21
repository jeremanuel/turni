import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: const Row(
          children: [
            SizedBox(
              width: 100,
            ),
            SideBar()
          ],
        ),
      ),
    );

  }
}

class SideBar extends StatelessWidget {
  const SideBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          
        },
        child:const Column(
          children: [
            SizedBox(
              width: 100,
              child: Text("hola"),
            )
          ]
        ))
    );
  }
}