import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/utils/backend_services/firestore_file_service.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/navigation_services/navigation_helper.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_bottom_navbar.dart';

class SavedFilesScreen extends StatefulWidget {
  const SavedFilesScreen({super.key});

  @override
  State<SavedFilesScreen> createState() => _SavedFilesScreenState();
}

class _SavedFilesScreenState extends State<SavedFilesScreen> {
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _initializeVoiceSystem();
  }

  Future<void> _initializeVoiceSystem() async {
    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    voiceService.autoRestart = false;

    voiceService.onResult = (recognizedText) {
      commandHandler.handleCommand(context, 'saved_files', recognizedText);
    };

    voiceService.autoRestart = true;

    await voiceService.init();
  }

  @override
  void dispose() {
    voiceService.uninitialize();
    super.dispose();
  }

  final FirestoreFileService _firestoreFileService = FirestoreFileService();

  Future<List<LessonFile>> _loadFilesForChild() async {
    final user = FirebaseAuth.instance.currentUser;
    final childUid = user?.uid;

    if (childUid == null) return [];

    try {
      final filesData = await _firestoreFileService.getFilesForChild(childUid);
      return filesData
          .map((fileData) => LessonFile.fromFirestore(fileData))
          .toList();
    } catch (e) {
      print('Error loading files for child: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          const CustomAppbar(),
          Expanded(
            child: FutureBuilder<List<LessonFile>>(
              future: _loadFilesForChild(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No files shared with you yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final files = snapshot.data!;
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) => _buildFileCard(files[index]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildFileCard(LessonFile file) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getFileTypeColor(file.fileType),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileTypeIcon(file.fileType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          file.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uploaded: ${file.formattedUploadDate}'),
            Text('${file.fileType} • ${file.formattedFileSize}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download, color: Colors.blue),
          onPressed: () {
            // Implement download functionality
            _downloadFile(file);
          },
        ),
        onTap: () {
          // Convert to map to preserve all fields during navigation
          final fileMap = file.toFullMap();
          NavigationHelper.goTo(
            context,
            'single_file_screen',
            arguments: {'fileData': fileMap},
          );
        },
      ),
    );
  }

  void _downloadFile(LessonFile file) {
    // Implement file download logic
    // You can use the fileUrl from PocketBase
  }
  // File content is stored as base64 in fileContent field
}

// Keep your existing _getFileTypeColor and _getFileTypeIcon methods
Color _getFileTypeColor(String type) {
  switch (type.toUpperCase()) {
    case 'PDF':
      return Colors.red;
    case 'DOC':
      return Colors.blue;
    case 'PPT':
      return Colors.orange;
    case 'MP4':
      return Colors.purple;
    case 'MP3':
      return Colors.green;
    case 'IMAGE':
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
      return Icons.description;
    case 'PPT':
      return Icons.slideshow;
    case 'MP4':
      return Icons.videocam;
    case 'MP3':
      return Icons.audiotrack;
    case 'IMAGE':
      return Icons.image;
    default:
      return Icons.insert_drive_file;
  }
}
