import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashAnimation extends StatelessWidget {

  final Widget child;
  final double width;
  final double height;  
  final Color? color;

      SplashAnimation({
    required this.child,
    required this.width,
    required this.height,
    this.color
  });



  @override
  Widget build(BuildContext context) {

    final maxDimension = max(height, width);
    
    
    return Container(
        alignment: Alignment.topLeft,
        height: height,
        child: child.animate().custom(
          begin: 0,
          end: maxDimension,
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) {
            return Opacity(
              opacity: value / maxDimension,
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(maxDimension + 8 - value), 
                    bottomRight: Radius.circular(maxDimension + 8 - value), 
                    topRight: Radius.circular(maxDimension + 8 - value), 
                    topLeft: const Radius.circular(8)
                  ),
                ),
                
                height: value,
                width: value,
                child: child,
              ),
            );
            
          },
        ),
      );
  }
}