import 'package:audoria/widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../widgets/custom_list_tile.dart';

class AllLessonsScreen extends StatefulWidget {
  const AllLessonsScreen({super.key});

  @override
  State<AllLessonsScreen> createState() => _AllLessonsScreenState();
}

class _AllLessonsScreenState extends State<AllLessonsScreen> {
  List<Map<String, String>> lessons = [
    {'title': 'Math - Lesson 1', 'date': '2 Feb, 2025'},
    {'title': 'English - Lesson 3', 'date': '3 Feb, 2025'},
    {'title': 'English - Lesson 4', 'date': '4 Feb, 2025'},
    {'title': 'History - Lesson 2', 'date': '7 Feb, 2025'},
    {'title': 'Science - Lesson 1', 'date': '10 Feb, 2025'},
    {'title': 'Geographic - Lesson 3', 'date': '20 Feb, 2025'},
  ];

  PlatformFile? selectedFile;
  String? selectedFileName;
  bool isUploading = false;

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
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFile = result.files.first;
          selectedFileName = selectedFile!.name;
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

    setState(() {
      isUploading = true;
    });

    try {
      // Simulate file upload process
      await Future.delayed(const Duration(seconds: 2));

      // Generate lesson title from filename
      String lessonTitle = _generateLessonTitle(selectedFileName!);
      String currentDate = _getCurrentDate();

      // Add new lesson to the end of the list
      setState(() {
        lessons.add({'title': lessonTitle, 'date': currentDate});
      });

      // Reset file selection
      setState(() {
        selectedFile = null;
        selectedFileName = null;
        isUploading = false;
      });

      Navigator.pop(context);
      _showSuccessSnackBar('Lesson uploaded successfully!');
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

  String _getCurrentDate() {
    DateTime now = DateTime.now();
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${now.day} ${months[now.month - 1]}, ${now.year}';
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
                                    ).withOpacity(0.3),
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
                  Center(child: CustomText.subtitle("All Lessons")),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            CustomListTile(
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
