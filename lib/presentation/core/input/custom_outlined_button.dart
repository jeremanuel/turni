import 'package:flutter/material.dart';

class CustomOutlinedButton extends StatefulWidget {
  final Function()? onPressed;
  final Widget child;
  const CustomOutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  State<CustomOutlinedButton> createState() => _CustomOutlinedButtonState();
}

class _CustomOutlinedButtonState extends State<CustomOutlinedButton> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        style: OutlinedButton.styleFrom(),
        child: SizedBox(
          width: 160,
          child: isLoading
              ? const Center(
                  child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator()))
              : widget.child,
        ),
        onPressed: () async {
          setState(() {
            isLoading = true;
          });
          await widget.onPressed!.call();
          setState(() {
            isLoading = false;
          });
        });
  }
}
