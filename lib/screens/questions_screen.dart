import 'package:audoria/utils.dart';
import 'package:flutter/material.dart';

class QuestionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/back.png'),
            Center(
              child: Column(
                children: [
                  Text(
                    'Ask any question',
                    style: TextStyle(color: textColor, fontSize: 40),
                  ),
                  Text(
                    'listening...',
                    style: TextStyle(color: textColor, fontSize: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
