import 'package:flutter/material.dart';
import '../../../utils/responsive_builder.dart';

class Aligned {
  final Alignment follower;
  final Alignment target;
  final Offset offset;
  final bool shiftX;
  final bool shiftY;
  const Aligned({
    required this.follower,
    required this.target,
    this.offset = Offset.zero,
    this.shiftX = false,
    this.shiftY = false,
  });
}

class DropdownWidget extends StatefulWidget {
  const DropdownWidget({
    super.key,
    required this.child,
    required this.menuWidget,
    required this.dropdownController,
    this.aligned,
    this.obscureBackground = true,
    this.onClose, 
    this.menuHeight,
  });

  final Function()? onClose;
  final Widget child;
  final Widget menuWidget;
  final DropdownController dropdownController;
  final Aligned? aligned;
  final bool obscureBackground;
  final double? menuHeight;

  @override
  State<DropdownWidget> createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
  double? _realMenuHeight;
  bool isVisible = false;
  late final OverlayPortalController _overlayController;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();

  @override
  void initState() {
    _overlayController = OverlayPortalController();
    initializeDropdowncontroller();
    super.initState();
  }

  void initializeDropdowncontroller() {
    widget.dropdownController.hide = () {
      setState(() {
        isVisible = false;
        _overlayController.hide();
        widget.onClose?.call();
      });
    };
    widget.dropdownController.show = () {
      if (ResponsiveBuilder.isMobile(context)) {
        showDialog(context: context, builder: (context) => buildMenu(context));
      } else {
        setState(() {
          isVisible = true;
          _overlayController.show();
        });
      }
    };
    widget.dropdownController.toggle = () {
      if (ResponsiveBuilder.isMobile(context)) {
        showDialog(context: context, builder: (context) => buildMenu(context));
      } else {
        setState(() {
          isVisible = !isVisible;
          if (isVisible) {
            _overlayController.show();
          } else {
            _overlayController.hide();
            widget.onClose?.call();
          }
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBuilder.isMobile(context)) {
      return GestureDetector(
        onTap: () {
          showDialog(context: context, builder: (context) => buildMenu(context));
        },
        child: widget.child,
      );
    }

    final aligned = widget.aligned ?? const Aligned(follower: Alignment.topLeft, target: Alignment.bottomLeft, offset: Offset(0, 8));

    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyedSubtree(
        key: _childKey,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (context) => Stack(
            children: [
              if (widget.obscureBackground)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        isVisible = false;
                        _overlayController.hide();
                        widget.onClose?.call();
                      });
                    },
                    child: Container(
                      color: const Color.fromARGB(104, 0, 0, 0),
                    ),
                  ),
                ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                followerAnchor: aligned.follower,
                targetAnchor: aligned.target,
                offset: _getDropdownOffset(context, aligned.offset),
                child: TweenAnimationBuilder(
                  tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
                  duration: kThemeAnimationDuration,
                  curve: Curves.easeOut,
                  builder: (context, progress, child) {
                    return Transform(
                      transform: Matrix4.translationValues(0, (progress - 1) * 50, 0),
                      child: Opacity(
                        opacity: progress,
                        child: child,
                      ),
                    );
                  },
                  child: buildMenu(context),
                ),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }

  Widget buildMenu(BuildContext context) {
    final menuWidget = SizedBox(
      key: _menuKey,
      width: 300,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: widget.menuWidget,
      ),
    );

    // Recalcula el alto real del menú después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuRenderBox = _menuKey.currentContext?.findRenderObject() as RenderBox?;
      if (menuRenderBox != null) {
        final newHeight = menuRenderBox.size.height;
        if (_realMenuHeight != newHeight) {
          setState(() {
            _realMenuHeight = newHeight;
          });
        }
      }
    });

    if (ResponsiveBuilder.isMobile(context)) {
      return Dialog(
        child: menuWidget,
      );
    }

    return menuWidget;
  }

  Offset _getDropdownOffset(BuildContext context, Offset customOffset) {
  const menuWidth = 300.0;
  // Usa el alto real si está disponible, si no usa el estimado
  double menuHeight = _realMenuHeight ?? 48.0 * 6;
   
    final screenSize = MediaQuery.of(context).size;
      RenderBox? renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    final targetPosition = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

    double dx = customOffset.dx;
    double dy = customOffset.dy;

    // Si el menú se sale por la derecha
    if (targetPosition.dx + dx + menuWidth > screenSize.width) {
      dx = screenSize.width - (targetPosition.dx + menuWidth) - 16;
    }    
    // Si el menú se sale por abajo (no entra en Y)
    final bottomOverflow = (targetPosition.dy + dy + menuHeight) - screenSize.height;
    if (bottomOverflow > 0) {
      // Coloca el menú justo por encima del child
      dy = -menuHeight;
      // Si el menú se sale por arriba de la pantalla, ajusta solo lo necesario para que entre
      final espacioArriba = targetPosition.dy + dy;
      if (espacioArriba < 0) {
        dy -= espacioArriba;
      }
    }
    return Offset(dx, dy);
  }
}

class DropdownController {
  Function()? hide;
  Function()? show;
  Function()? toggle;
  void dispose() {
    hide = null;
    show = null;
    toggle = null;
  }
}