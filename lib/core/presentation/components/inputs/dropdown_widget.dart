import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

import '../../../utils/responsive_builder.dart';

class DropdownWidget extends StatefulWidget {
  
  const DropdownWidget({super.key, required this.child, required this.menuWidget, required this.dropdownController, this.aligned});

  final Widget child;
  final Widget menuWidget;
  final DropdownController dropdownController;
  final Aligned? aligned;

  @override
  State<DropdownWidget> createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
    bool isVisible = false;

  @override
  void initState() {
    initializeDropdowncontroller();
    super.initState();
  }

  void initializeDropdowncontroller() {
       widget.dropdownController.hide = () {
        setState(() {
          isVisible = false;
        });
    };
    widget.dropdownController.show = () {
      if(ResponsiveBuilder.isMobile(context)) {
        showDialog(context: context, builder: (context) => buildMenu(context),);
      }

      setState(() {
        isVisible = true;
      });
    };
    
    widget.dropdownController.toggle = () {
      if(ResponsiveBuilder.isMobile(context)) {
        showDialog(context: context, builder: (context) => buildMenu(context),);
      }
      setState(() {
        isVisible = !isVisible;
      });
    };
  }
  

  @override
  Widget build(BuildContext context) {

    if(ResponsiveBuilder.isMobile(context)){
      return GestureDetector(
        onTap: () {
          showDialog(context: context, builder: (context) => buildMenu(context),);
        },
        child: widget.child
      );
    }

    return PortalTarget(
      visible: isVisible,
      portalFollower: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          setState(() {
            isVisible = false;
          });
        },        
      ),
      child: PortalTarget(
        visible: isVisible,
        anchor: aligment(),
        portalFollower: TweenAnimationBuilder(
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
            child: buildMenu(context)),
        child: widget.child,
      ),
    );
  }

  Widget buildMenu(BuildContext context) {
    final menuWidget = SizedBox(
            width: 300,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(8)),              
              child: widget.menuWidget,
              
            ),
    );
  
    if(ResponsiveBuilder.isMobile(context)) {
      return Dialog(
        child: menuWidget,
      );
    }

    return menuWidget;
  }

  
  Aligned aligment() {
    
    if(widget.aligned != null) return widget.aligned!;

    return const Aligned(
          follower: Alignment.topCenter,
          target: Alignment.bottomCenter,
          offset: Offset(0, 8),
          shiftToWithinBound:  AxisFlag(x: true,y: true ));
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