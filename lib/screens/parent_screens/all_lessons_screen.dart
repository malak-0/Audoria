import 'package:audoria/utils/pocketbase_service.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../models/lesson_file_model.dart';

class AllLessonsScreen extends StatefulWidget {
  const AllLessonsScreen({super.key});

  @override
  State<AllLessonsScreen> createState() => _AllLessonsScreenState();
}

class _AllLessonsScreenState extends State<AllLessonsScreen> {
  final PocketBaseService _pocketBaseService = PocketBaseService();
  List<LessonFile> lessons = [];
  bool isLoading = true;
  bool isServerConnected = false;

  PlatformFile? selectedFile;
  String? selectedFileName;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Check if PocketBase server is running
      isServerConnected = await _pocketBaseService.isServerRunning();

      if (isServerConnected) {
        await _loadLessons();
      }
    } catch (e) {
      _showErrorSnackBar('Error initializing data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadLessons() async {
    try {
      final records = await _pocketBaseService.getLessonFiles();
      setState(() {
        lessons = records
            .map((record) => LessonFile.fromPocketBase(record.data))
            .toList();
      });
    } catch (e) {
      _showErrorSnackBar('Error loading lessons: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'txt',
          'mp4',
          'mp3',
          'jpg',
          'png',
        ],
        allowMultiple: false,
        withData: true, // This ensures file bytes are loaded
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes == null) {
          _showErrorSnackBar('Failed to load file data. Please try again.');
          return;
        }

        setState(() {
          selectedFile = file;
          selectedFileName = file.name;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  Future<void> _uploadLesson() async {
    if (selectedFile == null) {
      _showErrorSnackBar('Please select a file first');
      return;
    }

    if (selectedFile!.bytes == null) {
      _showErrorSnackBar(
        'File data is not available. Please select the file again.',
      );
      return;
    }

    if (!isServerConnected) {
      _showErrorSnackBar(
        'PocketBase server is not running. Please start the server.',
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // Generate lesson title from filename
      String lessonTitle = _generateLessonTitle(selectedFileName!);

      // Upload file to PocketBase
      await _pocketBaseService.uploadLessonFile(
        file: selectedFile!,
        title: lessonTitle,
      );

      // Reload lessons from server
      await _loadLessons();

      // Reset file selection
      setState(() {
        selectedFile = null;
        selectedFileName = null;
        isUploading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('Lesson uploaded successfully!');
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      _showErrorSnackBar('Error uploading file: $e');
    }
  }

  String _generateLessonTitle(String fileName) {
    // Remove file extension
    String nameWithoutExt = fileName.split('.').first;

    // Capitalize first letter of each word
    List<String> words = nameWithoutExt.split(' ');
    words = words
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word,
        )
        .toList();

    return words.join(' ');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _deleteLesson(LessonFile lesson) async {
    if (!isServerConnected) {
      _showErrorSnackBar('PocketBase server is not running.');
      return;
    }

    try {
      await _pocketBaseService.deleteLessonFile(lesson.id);
      await _loadLessons();
      _showSuccessSnackBar('Lesson deleted successfully!');
    } catch (e) {
      _showErrorSnackBar('Error deleting lesson: $e');
    }
  }

  void _showDeleteDialog(LessonFile lesson) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Lesson'),
          content: Text('Are you sure you want to delete "${lesson.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteLesson(lesson);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showFileInfo(LessonFile lesson) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(lesson.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filename: ${lesson.filename}'),
              const SizedBox(height: 8),
              Text('Type: ${lesson.fileType.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Size: ${lesson.formattedFileSize}'),
              const SizedBox(height: 8),
              Text('Uploaded: ${lesson.formattedUploadDate}'),
              if (lesson.fileUrl != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'File URL:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  lesson.fileUrl!,
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: isUploading
                          ? null
                          : () async {
                              await _pickFile();
                              setDialogState(() {});
                            },
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: selectedFile != null
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                            style: BorderStyle.solid,
                            width: selectedFile != null ? 3 : 2,
                          ),
                          color: selectedFile != null
                              ? const Color(0xFFE8F5E8)
                              : Colors.grey.shade100,
                          boxShadow: selectedFile != null
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2E7D32,
                                    ).withValues(alpha: 0.3),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: selectedFile != null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF2E7D32),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Selected: $selectedFileName',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF2E7D32),
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Choose file',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black54,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (selectedFile != null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Supported formats: PDF, DOC, PPT, MP4, MP3, JPG, PNG',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUploading
                                ? Colors.grey
                                : selectedFile != null
                                ? const Color.fromARGB(255, 60, 116, 212)
                                : const Color(0xFF9BB9FF),
                            elevation: selectedFile != null ? 8 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isUploading
                              ? null
                              : () async {
                                  await _uploadLesson();
                                  setDialogState(() {});
                                },
                          child: isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Upload',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
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
                          onPressed: isUploading
                              ? null
                              : () {
                                  setState(() {
                                    selectedFile = null;
                                    selectedFileName = null;
                                  });
                                  Navigator.pop(context);
                                },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Inter',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(child: CustomText.subtitle("All Lessons")),
                      if (!isServerConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Offline Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : lessons.isEmpty
                        ? const Center(
                            child: Text(
                              'No lessons uploaded yet.\nTap the + button to upload your first lesson!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontFamily: 'Inter',
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Uploaded: ${lesson.formattedUploadDate}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        Text(
                                          '${lesson.fileType.toUpperCase()} • ${lesson.formattedFileSize}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black38,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _showDeleteDialog(lesson);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // You can add file preview/download functionality here
                                      _showFileInfo(lesson);
                                    },
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
