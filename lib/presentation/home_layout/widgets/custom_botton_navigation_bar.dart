import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';

class CustomBottomNavigationBar extends StatelessWidget {

  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({super.key, required this.selectedIndex, required this.onTap});


  @override
  Widget build(BuildContext context) {
    
    return  BottomNavigationBar(
      currentIndex: selectedIndex,      
      onTap: onTap,
      items: buildNavigationItems());
  }

  List<BottomNavigationBarItem>  buildNavigationItems() {

    final isAdmin = sl<AuthCubit>().isAdmin();

    if(!isAdmin){
    return const [
      BottomNavigationBarItem(label: "Turnos", icon: Icon(Icons.calendar_month), activeIcon: Icon(Icons.check)),
      BottomNavigationBarItem(label: "Perfil", icon: Icon(Icons.person), activeIcon: Icon(Icons.check))
    ];
    }

    return const [
        BottomNavigationBarItem(label: "Dashboard", icon: Icon(Icons.dashboard), activeIcon: Icon(Icons.dashboard)),
        BottomNavigationBarItem(label: "Turnos", icon: Icon(Icons.calendar_month), activeIcon: Icon(Icons.calendar_month)),
        BottomNavigationBarItem(label: "Perfil", icon: Icon(Icons.person), activeIcon: Icon(Icons.person))

    ];

  }
}

