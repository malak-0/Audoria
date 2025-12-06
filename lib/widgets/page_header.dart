import 'dart:io';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subTitle;
  final String? imagePath;

  const PageHeader({
    super.key,
    required this.title,
    this.subTitle,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 330),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        color: textColor.withOpacity(0.1),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 25.0, top: 40, right: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔙 Back Button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, color: textColor, size: 24),
              ),
            

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Subtitle
            if (subTitle != null)
              Row(
                children: [
                  Flexible(
                    child: Text(
                      subTitle!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Image preview
            if (imagePath != null)
              Center(
                child: Container(
                  width: 250,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}
