import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Fondo del login con una tarjeta centrada. Lo usan las pantallas que se ven
/// fuera del panel: el link de invitación y "sin acceso".
class AuthCardScaffold extends StatelessWidget {
  const AuthCardScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromRGBO(189, 163, 246, 1), Color.fromRGBO(103, 43, 234, 1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/img/logotype_white.svg',
                    semanticsLabel: 'Logo de Turni',
                    width: 138,
                    height: 46,
                  ),
                  const SizedBox(height: 32),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
