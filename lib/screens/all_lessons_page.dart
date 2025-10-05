import 'package:audoria/custom_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import '../custom_widgets/custom_appbar.dart';
import '../custom_widgets/custom_bottom_navbar.dart';
import '../custom_widgets/custom_listtile.dart';

class AllLessonsPage extends StatefulWidget {
  const AllLessonsPage({super.key});

  @override
  State<AllLessonsPage> createState() => _AllLessonsPageState();
}

class _AllLessonsPageState extends State<AllLessonsPage> {
  List<Map<String, String>> lessons = [
    {'title': 'Math - Lesson 1', 'date': '2 Feb, 2025'},
    {'title': 'English - Lesson 3', 'date': '3 Feb, 2025'},
    {'title': 'English - Lesson 4', 'date': '4 Feb, 2025'},
    {'title': 'History - Lesson 2', 'date': '7 Feb, 2025'},
    {'title': 'Science - Lesson 1', 'date': '10 Feb, 2025'},
    {'title': 'Geographic - Lesson 3', 'date': '20 Feb, 2025'},
  ];

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload New Lesson',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'inter',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // file picker will be here
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                      color: Colors.grey.shade100,
                    ),
                    child: const Center(
                      child: Text(
                        'Choose file',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontFamily: 'inter',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9BB9FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // Add new lesson logic will be here
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Upload',
                        style: TextStyle(
                          fontFamily: 'inter',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'inter',
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      body: Column(
        children: [
          const CustomAppbar(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF9BB9FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: CustomText.subtitle("All Lessons")),
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            CustomListtile(
                              title: lessons[index]['title']!,
                              subTitle: 'Uploaded: ${lessons[index]['date']}',
                              filePage: Container(),
                            ),
                            Divider(
                              color: Colors.black.withValues(alpha: 0.1),
                              thickness: 1,
                              height: 5,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: _showUploadDialog,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
