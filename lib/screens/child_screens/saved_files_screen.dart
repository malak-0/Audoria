import 'package:flutter/material.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../widgets/custom_text.dart';

class SavedFilesScreen extends StatefulWidget {
  const SavedFilesScreen({super.key});

  @override
  State<SavedFilesScreen> createState() => _SavedFilesScreenState();
}

class _SavedFilesScreenState extends State<SavedFilesScreen> {
  List<Map<String, dynamic>> savedFiles = [
    {
      'title': 'Math - Lesson 1',
      'date': '2 Feb, 2025',
      'type': 'PDF',
      'size': '2.4 MB',
    },
    {
      'title': 'English - Lesson 3',
      'date': '3 Feb, 2025',
      'type': 'DOC',
      'size': '1.8 MB',
    },
    {
      'title': 'History - Lesson 2',
      'date': '7 Feb, 2025',
      'type': 'PPT',
      'size': '5.2 MB',
    },
    {
      'title': 'Science - Lesson 1',
      'date': '10 Feb, 2025',
      'type': 'MP4',
      'size': '12.3 MB',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9BB9FF),
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
                  Center(child: CustomText.subtitle("Saved Files")),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: savedFiles.length,
                      itemBuilder: (context, index) {
                        return _buildFileCard(savedFiles[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF1A237E),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Color(0xFF4CAF50), size: 32),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getFileTypeColor(file['type']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getFileTypeIcon(file['type']),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Added on ${file['date']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${file['type']} • ${file['size']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            // Play button
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 72, 116, 220),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFileTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Colors.red;
      case 'DOC':
      case 'DOCX':
        return Colors.blue;
      case 'PPT':
      case 'PPTX':
        return Colors.orange;
      case 'MP4':
        return Colors.purple;
      case 'MP3':
        return Colors.green;
      case 'JPG':
      case 'PNG':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow;
      case 'MP4':
        return Icons.videocam;
      case 'MP3':
        return Icons.audiotrack;
      case 'JPG':
      case 'PNG':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}
