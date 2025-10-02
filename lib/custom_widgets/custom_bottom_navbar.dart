import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      color: Colors.white,
      backgroundColor: const Color(0xFF9BB9FF),
      buttonBackgroundColor: const Color(0xFF9BB9FF),
      items: <Widget>[
        Icon(Icons.person_outline_sharp, size: 30),
        Icon(Icons.home_outlined, size: 30),
        Icon(Icons.settings, size: 30),
      ],
      onTap: (index) {
        //Handle button tap
      },
    );
  }
}
