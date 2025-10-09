import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const CustomText._({
    required this.text,
    required this.style,
  });

  // Username
  factory CustomText.username(String text) {
    return CustomText._(
      text: text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF030303),
      ),
    );
  }

  // Subtitle text 
  factory CustomText.subtitle(String text) {
    return CustomText._(
      text: text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF030303),
      ),
    );
  }

  // Body text 
  factory CustomText.body(String text) {
    return CustomText._(
      text: text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF030303),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
    );
  }
}
