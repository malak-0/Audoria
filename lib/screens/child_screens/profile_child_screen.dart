import 'package:flutter/material.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/widgets/custom_bottom_navbar.dart';

class ProfileChildScreen extends StatefulWidget {
  final Map<String, String>? childData;

  const ProfileChildScreen({super.key, this.childData});

  @override
  State<ProfileChildScreen> createState() => _ProfileChildScreenState();
}

class _ProfileChildScreenState extends State<ProfileChildScreen> {
  @override
  Widget build(BuildContext context) {
    final data = widget.childData;

    return Scaffold(
      appBar: AppBar(
        title: CustomText.username('Profile'),
        backgroundColor: const Color(0xFF9BB9FF),
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
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                CustomText.username(data?['name'] ?? 'Child Name'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          CustomText.subtitle('Personal Information'),
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
              subtitle: Text(data?['name'] ?? 'Not set'),
            ),
          ),
          const SizedBox(height: 10),

          // Age Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.cake, color: Color(0xFF9BB9FF)),
              title: CustomText.body('Age'),
              subtitle: Text(data?['age'] ?? 'Not set'),
            ),
          ),
          const SizedBox(height: 10),

          // Grade Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.school, color: Color(0xFF9BB9FF)),
              title: CustomText.body('Grade'),
              subtitle: Text(data?['grade'] ?? 'Not set'),
            ),
          ),
          const SizedBox(height: 10),

          // School Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(
                Icons.location_city,
                color: Color(0xFF9BB9FF),
              ),
              title: CustomText.body('School'),
              subtitle: Text(data?['school'] ?? 'Not set'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
