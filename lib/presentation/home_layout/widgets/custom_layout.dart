import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/presentation/admin/desktop_layout.dart';
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
    final isDesktop = MediaQuery.of(context).size.width > 700;

    if(isDesktop){
     return DesktopLayout(child: child);
    }

    return buildMobileLayout(); 
  }

  Scaffold buildMobileLayout() {
    return Scaffold(
    body: child,
    bottomNavigationBar:  CustomBottomNavigationBar(
      selectedIndex: child.currentIndex,
      onTap: (index) => child.goBranch(index),
    ),
  );
  }
}