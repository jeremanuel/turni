import 'package:flutter/material.dart';

/// Cortes de pantalla del admin (ver diseño "Admin mobile — layout y
/// navegación"):
/// - celular: menos de [mobileMaxWidth] → barra de navegación inferior;
/// - tablet: hasta [desktopMinWidth] → menú lateral, paneles a pantalla completa;
/// - escritorio: desde [desktopMinWidth] → layout completo con panel lateral.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobileBuilder,
    required this.tabletBuilder,
    required this.desktopBuilder,
    super.key,
  });

  static const double mobileMaxWidth = 600;
  static const double desktopMinWidth = 1240;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) mobileBuilder;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) tabletBuilder;

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
  ) desktopBuilder;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMaxWidth && width < desktopMinWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMinWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= desktopMinWidth) {
          return desktopBuilder(context, constraints);
        } else if (constraints.maxWidth >= mobileMaxWidth) {
          return tabletBuilder(context, constraints);
        } else {
          return mobileBuilder(context, constraints);
        }
      },
    );
  }
}
