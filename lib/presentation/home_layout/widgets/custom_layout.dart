import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../admin/desktop_layout.dart';

import 'mobile_layout.dart';

class CustomLayout extends StatelessWidget {

  final StatefulNavigationShell child;

  const CustomLayout({super.key, 
    required this.child,
    required this.scaffoldKey
  });


  final GlobalKey<ScaffoldState> scaffoldKey;


  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    if(isDesktop){
     return DesktopLayout(scaffoldKey: scaffoldKey, child: child);
    }

    return MobileLayout(child: child,); 
  }


}