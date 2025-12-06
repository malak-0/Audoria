import 'package:audoria/utils/backend_services/firebase_helpers.dart';
import 'package:audoria/widgets/custom_appbar.dart';
import 'package:audoria/widgets/custom_bottom_navbar.dart';
import 'package:audoria/widgets/lottie_card.dart';
import 'package:audoria/data/parent_home_list.dart';
import 'package:audoria/utils/constants.dart';
import 'package:flutter/material.dart';

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
      appBar: const CustomAppbar(showBackButton: false),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section with enhanced design
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: textColor.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [bgColor, bgColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome,',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder(
                              future: getCurrentUsername(),
                              builder: (context, snapshot) {
                                final username = snapshot.data ?? 'Parent';
                                return Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 26,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Subtitle with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: textColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Track your child\'s progress',
                      style: TextStyle(
                        fontSize: 22,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Options List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: parentHomeOptionsList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: LottieCard(
                        parentHomeOptions: parentHomeOptionsList[index],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
