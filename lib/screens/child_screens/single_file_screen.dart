import 'package:audoria/widgets/lottie_card.dart';
import 'package:audoria/widgets/page_header.dart';
import 'package:audoria/data/single_file_list.dart';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';

class SingleFileScreen extends StatelessWidget {
  const SingleFileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          PageHeader(title: 'File 1', subTitle: 'os lecture 1'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: ListView.builder(
                itemCount: fileOptionsList.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      LottieCard(fileOptions: fileOptionsList[index]),
                      if (index != fileOptionsList.length - 1)
                        const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
