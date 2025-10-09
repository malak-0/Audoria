import 'dart:io';
import 'package:audoria/custom_widgets/custom_text.dart';
import 'package:audoria/utils.dart';
import 'package:flutter/widgets.dart';

class PageHeader extends StatelessWidget{
  final String title; 
  final String? subTitle;
  final String? imagePath;

  const PageHeader({super.key, required this.title, this.subTitle,  this.imagePath});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: imagePath!=null ? 260 : 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),bottomRight: Radius.circular(15)),
          color: textColor.withValues(alpha: 0.1)
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/images/back.png',width: 20,height: 20,),
                Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    SizedBox(height: 5,),
                    CustomText.username(title),
                    if (subTitle != null)
                      CustomText.subtitle(subTitle!),
                    if (imagePath!= null) 
                      Center(child: Image.file(File(imagePath!),width: 120,height: 150))
                  ],
                  ),
                )
                ],),
          ),
          );
  } 
}