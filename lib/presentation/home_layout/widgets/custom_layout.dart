import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/presentation/home_layout/widgets/custom_botton_navigation_bar.dart';
import 'package:turni/presentation/home_layout/widgets/custom_drawer.dart';

class CustomLayout extends StatelessWidget {

  final StatefulNavigationShell child;

    const CustomLayout({
      super.key, 
      required this.child
  });



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