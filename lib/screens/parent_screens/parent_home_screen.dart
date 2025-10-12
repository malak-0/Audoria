import 'package:audoria/widgets/custom_bottom_navbar.dart';
import 'package:audoria/widgets/lottie_card.dart';
import 'package:audoria/data/parent_home_list.dart';
import 'package:audoria/utils.dart';
import 'package:flutter/material.dart';
import 'package:audoria/widgets/custom_text.dart';

class ParentHomeScreen extends StatelessWidget {
  final String username;
  final String childName;

  const ParentHomeScreen({
    super.key,
    this.username = 'User',
    this.childName = 'Child',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 50, left: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.person_pin, size: 50),
                  const SizedBox(width: 8),
                  CustomText.username(username),
                ],
              ),
              const SizedBox(height: 50),
              CustomText.subtitle("Track $childName’s progress"),

              Expanded(
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: parentHomeOptionsList.length,
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LottieCard(
                            parentHomeOptions: parentHomeOptionsList[index],
                          ),
                          if (index != parentHomeOptionsList.length - 1)
                            const SizedBox(height: 50),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
