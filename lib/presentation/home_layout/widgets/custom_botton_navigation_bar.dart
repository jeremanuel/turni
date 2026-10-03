import 'package:flutter/material.dart';
import '../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar(
      {super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        items: buildNavigationItems(context));
  }

  List<BottomNavigationBarItem> buildNavigationItems(context) {
    final isAdmin = sl<AuthCubit>().isAdmin();

    if (!isAdmin) {
      return const [
        BottomNavigationBarItem(
            label: "Home",
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded)),
        BottomNavigationBarItem(
            label: "Perfil",
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.check))
      ];
    }

    return  [
      const BottomNavigationBarItem(
          label: "Dashboard",
          icon: Icon(Icons.dashboard),
          activeIcon: Icon(Icons.dashboard)),
      const BottomNavigationBarItem(
          label: "Turnos",
          icon: Icon(Icons.calendar_month),
          activeIcon: Icon(Icons.calendar_month)),
      const BottomNavigationBarItem(
        label: "Clientes",
        icon: Icon(Icons.person),
        activeIcon: Icon(Icons.person)),
      const BottomNavigationBarItem(
          label: "Perfil",
          icon: Icon(Icons.build),
          activeIcon: Icon(Icons.build))
    ];
  }
}
