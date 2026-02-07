import 'package:flutter/material.dart';

class PopButton extends StatefulWidget {
  const PopButton({super.key, required this.button});

  final Widget button;

  @override
  State<PopButton> createState() => _PopButtonState();
}

class _PopButtonState extends State<PopButton> {
  double _scale = 1.0;

  void pop() {
    setState(() => _scale = 1.1);

    Future.delayed(const Duration(milliseconds: 60), () {
      setState(() => _scale = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      child: widget.button,
    );
  }
}
