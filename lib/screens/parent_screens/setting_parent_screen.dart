import 'package:flutter/material.dart';
import 'package:audoria/screens/register_screen.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:audoria/widgets/custom_bottom_navbar.dart';
import 'package:audoria/utils/backend_services/firebase_helpers.dart';

class SettingParent extends StatefulWidget {
  final List<Map<String, String>> childrenData;
  final String parentName;
  final String parentEmail;

  const SettingParent({
    super.key,
    required this.childrenData,
    required this.parentName,
    required this.parentEmail,
  });

  @override
  State<SettingParent> createState() => _SettingParentState();
}

class _SettingParentState extends State<SettingParent> {
  late List<Map<String, String>> _childrenData;

  @override
  void initState() {
    super.initState();
    _childrenData = List<Map<String, String>>.from(widget.childrenData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText.username('Settings'),
        backgroundColor: const Color(0xFF9BB9FF),
        centerTitle: true,
      ),

      // حذف الـ Drawer
      drawer: null,

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          CustomText.subtitle('General'),
          const SizedBox(height: 15),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF9BB9FF)),
              title: CustomText.subtitle('Account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () => _showAccountDialog(context),
            ),
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(Icons.child_care, color: Color(0xFF9BB9FF)),
              title: CustomText.subtitle('Children'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () => _showChildrenDialog(context),
            ),
          ),

          const SizedBox(height: 40),

          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout),
              label: CustomText.username('Logout'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  void _showAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText.body('Account'),
              const SizedBox(height: 20),
              _buildInfoRow('Name', widget.parentName),
              _buildInfoRow('Email', widget.parentEmail),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9BB9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: CustomText.body('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChildrenDialog(BuildContext context) {
    final children = _childrenData;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 320,
          constraints: const BoxConstraints(maxHeight: 400, minHeight: 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText.body('Children'),
              const SizedBox(height: 20),
              if (children.isEmpty)
                CustomText.body('No children added yet.')
              else
                Flexible(
                  child: ListView.builder(
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      final child = children[index];
                      return ListTile(
                        title: CustomText.body(child['name'] ?? 'Unnamed'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showChildDetails(context, child),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChildDetails(BuildContext context, Map<String, String> child) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                child['name'] ?? 'Child Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildInfoRow('Age', child['age']),
              _buildInfoRow('Grade', child['grade']),
              _buildInfoRow('School', child['school']),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9BB9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: CustomText.body('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : 'Not set')),
        ],
      ),
    );
  }
}
