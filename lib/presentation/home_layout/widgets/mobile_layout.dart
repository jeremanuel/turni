
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/presentation/home_layout/widgets/custom_botton_navigation_bar.dart';
import 'package:turni/presentation/home_layout/widgets/custom_drawer.dart';

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
    bottomNavigationBar:  CustomBottomNavigationBar(
      selectedIndex: child.currentIndex,
      onTap: (index) => child.goBranch(index),
    ),
      );
  }
}