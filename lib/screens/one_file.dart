import 'package:audoria/custom_widgets/lottie_card.dart';
import 'package:audoria/custom_widgets/page_header.dart';
import 'package:audoria/data/one_file_list.dart';
import 'package:audoria/utils.dart';
import 'package:flutter/material.dart';

class OneFile extends StatelessWidget{
  const OneFile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
          children: [
            PageHeader(title: 'File 1', subTitle: 'os lecture 1',),
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
            )
          ],),
    );
  }
}