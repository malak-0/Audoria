import 'package:flutter/material.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/widgets/custom_bottom_navbar.dart';

class ProfileParentScreen extends StatefulWidget {
  final String parentName;
  final String parentEmail;

  const ProfileParentScreen({
    super.key,
    required this.parentName,
    required this.parentEmail,
  });

  @override
  State<ProfileParentScreen> createState() => _ProfileParentScreenState();
}

class _ProfileParentScreenState extends State<ProfileParentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText.username('Profile'),
        backgroundColor: const Color(0xFF9BB9FF),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          // Profile Picture Section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF9BB9FF),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                CustomText.username(widget.parentName),
              ],
            ),
          ),
          const SizedBox(height: 40),
          CustomText.subtitle('Account Information'),
          const SizedBox(height: 15),

          // Name Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF9BB9FF)),
              title: CustomText.body('Name'),
              subtitle: Text(widget.parentName),
            ),
          ),
          const SizedBox(height: 10),

          // Email Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF9BB9FF)),
              title: CustomText.body('Email'),
              subtitle: Text(widget.parentEmail),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
