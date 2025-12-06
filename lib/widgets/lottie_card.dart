import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/models/file_options_model.dart';
import 'package:audoria/models/image_options_model.dart';
import 'package:audoria/models/parent_home_options.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieCard extends StatelessWidget {
  final FileOptionsModel? fileOptions;
  final ImageOptionsModel? imageOptions;
  final ParentHomeOptionsModel? parentHomeOptions;
  final VoidCallback? onTap; // Allow parent to override tap behavior

  const LottieCard({
    super.key,
    this.fileOptions,
    this.imageOptions,
    this.parentHomeOptions,
    this.onTap,
  });

  Widget buildCustomContainer({
    double? height,
    double? width,
    required String title,
    required String iconPath,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 150, // Reduced from 190
        width: width ?? 150, // Reduced from 190
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25), // Slightly smaller radius
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Reduced padding
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset(
                  iconPath,
                  width: 70, // Reduced from 100
                  height: 70, // Reduced from 100
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0), // Added horizontal padding
                  child: CustomText.username(
                    title,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fileOptions != null) {
      return GestureDetector(
        onTap:
            onTap ??
            (fileOptions!.routeName != null
                ? () => Navigator.pushNamed(context, fileOptions!.routeName!)
                : null),
        child: Container(
          height: 160, // Reduced from 190
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // Reduced radius
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0), // Adjusted padding
            child: Row(
              children: fileOptions!.isReversed
                  ? [
                      Lottie.asset(
                        fileOptions!.iconPath,
                        width: 100, // Reduced from 120
                        height: 100, // Reduced from 120
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 5), // Reduced spacing
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Added horizontal padding
                          child: CustomText.username(
                            fileOptions!.title,
                          ),
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0), // Added horizontal padding
                          child: CustomText.username(
                            fileOptions!.title,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      Lottie.asset(
                        fileOptions!.iconPath,
                        width: 100, // Reduced from 120
                        height: 100, // Reduced from 120
                        fit: BoxFit.contain,
                      ),
                    ],
            ),
          ),
        ),
      );
    }

    if (imageOptions != null) {
      return buildCustomContainer(
        iconPath: imageOptions!.iconPath,
        title: imageOptions!.title,
      );
    }

    if (parentHomeOptions != null) {
      return buildCustomContainer(
        iconPath: parentHomeOptions!.iconPath,
        title: parentHomeOptions!.title,
        onTap: () {
          Navigator.pushNamed(context, parentHomeOptions!.routeName);
        },
      );
    }

    return const Placeholder();
  }
}