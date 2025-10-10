import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color color = Color(0xFF030303);
  final IconData icon;
  final bool isObscureText;
  CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isObscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFee8a2c), width: 2),
        ),
        prefixIcon: Icon(icon, color: Color(0xFF9bb9ff), size: 25),
        label: Text(hintText, style: TextStyle(color: color, fontSize: 17)),
        labelStyle: TextStyle(color: color, fontSize: 17),
        suffixIcon: isObscureText
            ? Icon(Icons.visibility, color: Color(0xFF9bb9ff), size: 25)
            : null,
      ),
      style: TextStyle(color: color, fontSize: 17),
    );
  }
}
