import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CustomBottomNavigationBar extends StatelessWidget {

  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({super.key, required this.selectedIndex, required this.onTap});


  @override
  Widget build(BuildContext context) {
    
    return  BottomNavigationBar(
      currentIndex: selectedIndex,      
      onTap: onTap,
      items: const [
      BottomNavigationBarItem(label: "Turnos", icon: Icon(Icons.calendar_month), activeIcon: Icon(Icons.check)),
      BottomNavigationBarItem(label: "Perfil", icon: Icon(Icons.person), activeIcon: Icon(Icons.check))
    ]);
  }
}

