
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_drawer.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({
    super.key,
    required this.child,
  });

  final StatefulNavigationShell child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: CustomDrawer(),
      body: child,
    );
  }
}