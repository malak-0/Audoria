import 'package:audoria/utils/navigation_services/navigation_helper.dart';
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
          ? () => NavigationHelper.goTo(context, routeName!)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: routeName != null
                ? () => NavigationHelper.goTo(context, routeName!)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9BB9FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
