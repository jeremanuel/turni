import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../admin/desktop_layout.dart';
import '../../admin/mobile/admin_mobile_layout.dart';
import '../../core/cubit/auth/auth_cubit.dart';
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
    final width = MediaQuery.sizeOf(context).width;

    // Admin: barra inferior en el celular, menú lateral desde tablet.
    if (sl<AuthCubit>().isAdmin()) {
      if (width < ResponsiveBuilder.mobileMaxWidth) return AdminMobileLayout(shell: child);
      return DesktopLayout(scaffoldKey: scaffoldKey, child: child);
    }

    final isDesktop = width > 700;
    if(isDesktop){
     return DesktopLayout(scaffoldKey: scaffoldKey, child: child);
    }
    return MobileLayout(child: child,);
  }
}
