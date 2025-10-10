import 'package:audoria/widgets/lottie_card.dart';
import 'package:audoria/widgets/page_header.dart';
import 'package:audoria/data/captured_image_list.dart';
import 'package:audoria/utils.dart';
import 'package:flutter/material.dart';

class CapturedImageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          PageHeader(title: 'Image'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: imageOptionsList.length,
                itemBuilder: (context, index) =>
                    LottieCard(imageOptions: imageOptionsList[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
