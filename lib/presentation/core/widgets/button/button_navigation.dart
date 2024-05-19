import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ButtonNavigation extends StatelessWidget {
  const ButtonNavigation({
    super.key,
    this.onPressed,
    this.accesibility,
    this.text,
    this.svg,
  });

  final String? accesibility;
  final String? svg;
  final String? text;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    const color = Color.fromRGBO(159, 121, 242, 1);
    return TextButton(
      onPressed: onPressed,
      child: SizedBox(
        height: 56,
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              color: color,
              svg ?? 'assets/img/tennis.svg',
              semanticsLabel: accesibility ?? "",
              width: 32,
              height: 32,
            ),
            Text(
              text ?? 'Default',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 10, color: color),
            )
          ],
        ),
      ),
    );
  }
}
