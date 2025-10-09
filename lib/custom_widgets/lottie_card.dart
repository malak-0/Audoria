import 'package:audoria/custom_widgets/custom_text.dart';
import 'package:audoria/models/file_options_model.dart';
import 'package:audoria/models/image_options_model.dart';
import 'package:audoria/models/parent_home_options.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieCard extends StatelessWidget {
  final FileOptionsModel? fileOptions;
  final ImageOptionsModel? imageOptions;
  final ParentHomeOptionsModel? parentHomeOptions;

  const LottieCard({
    super.key,
    this.fileOptions,
    this.imageOptions,
    this.parentHomeOptions,
  });

  Widget build_custom_container({
    double? height,
    double? width,
    required String title, 
    required String iconPath
    })
    {
      return Container(
      height: height?? 190,
      width: width?? 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                iconPath,
                width: 100,
                height: 100,
                fit: BoxFit.fitHeight,
              ),
              CustomText.username(title),
            ],
          ),
        ),
      ),
    );
    }

  @override
  Widget build(BuildContext context) {

    if (fileOptions != null) {
      final rowChildren = [
        Center(child: CustomText.username(fileOptions!.title)),
        const Spacer(),
        Lottie.asset(
          fileOptions!.iconPath,
          width: 150,
          height: 150,
          fit: BoxFit.fitWidth,
        ),
      ];

      return Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(21.0),
          child: Row(
            children: fileOptions!.isReversed
                ? rowChildren.reversed.toList()
                : rowChildren,
          ),
        ),
      );
    }

    if (imageOptions != null){
      return build_custom_container(
        iconPath: imageOptions!.iconPath,
        title: imageOptions!.title
        ); 
    }

    if (parentHomeOptions != null){
      return build_custom_container(
        iconPath: parentHomeOptions!.iconPath,
        title: parentHomeOptions!.title
        );
    }
  return const Placeholder();
    
  }
}
