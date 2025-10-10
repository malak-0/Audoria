import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Widget destinationPage;
  final String text;
  final double radius;
  final int color;
  final int textColor;

  const CustomButton({
    super.key,
    required this.destinationPage,
    required this.text,
    required this.radius,
    required this.color,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: EdgeInsets.all(15),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        },
        child: Text(
          text,
          style: TextStyle(
            color: Color(textColor),
            fontFamily: 'inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
