import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final String? routeName;

  const CustomCard({
    super.key,
    required this.imagePath,
    required this.label,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: routeName != null
          ? () => Navigator.pushNamed(context, routeName!)
          : null,
      child: Container(
        width: 140,
        height: 140,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 60,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
