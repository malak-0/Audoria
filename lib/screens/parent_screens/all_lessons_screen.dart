import 'package:audoria/utils/backend_services/pocketbase_service.dart';
import 'package:audoria/widgets/custom_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final user = FirebaseAuth.instance.currentUser;
  String? get uid => user?.uid;
  List<LessonFile> lessons = [];
  bool isLoading = true;
  bool isServerConnected = false;

  PlatformFile? selectedFile;
  String? selectedFileName;
  bool isUploading = false;

  List<String> selectedChildren = [];
  List<Map<String, dynamic>> availableChildren = [
    {'uid': 'child1_uid', 'name': 'Child 1'},
    {'uid': 'child2_uid', 'name': 'Child 2'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final childrenSnapshot = await FirebaseFirestore.instance
        .collection('parents')
        .doc(uid)
        .collection('children')
        .get();
    setState(() {
      availableChildren = childrenSnapshot.docs.map((doc) => {
        'uid': doc.id,
        'name': doc.data()['name'],
      }).toList();
    });
  }

  Future<void> _initializeData() async {
    try {
      print('Starting _initializeData');
      print('Current Firebase User UID: $uid');
      print('Current User Email: ${user?.email}');

      // Check if PocketBase server is running
      print('Checking PocketBase server connection...');
      isServerConnected = await _pocketBaseService.isServerRunning();
      print('Server connected: $isServerConnected');

      if (isServerConnected && uid != null) {
        await _loadParentFiles();
    } else {
      print('Cannot load files - Server: $isServerConnected, UID: $uid');
    }
    } catch (e) {
      _showErrorSnackBar('Error initializing data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadParentFiles() async {
    try {
      print('Loading parent files...');
      final records = await _pocketBaseService.getFilesByParent(uid!);
      
      print('Processing ${records.length} records...');
      List<LessonFile> loadedLessons = [];
      
      for (var record in records) {
        try {
          print('Processing record: ${record.id}');
          final lesson = LessonFile.fromPocketBase(record.data);
          final fileUrl = _pocketBaseService.getFileUrl(record);
          final lessonWithUrl = lesson.copyWith(fileUrl: fileUrl);
          loadedLessons.add(lessonWithUrl);
          print('Loaded file: ${lesson.title} (ID: ${lesson.id})');
        } catch (e) {
          print('Error processing record ${record.id}: $e');
        }
      }
      
      setState(() {
        lessons = loadedLessons;
      });
      
      print('Loaded ${lessons.length} lessons successfully');
      
      // If no lessons found, show a more specific message
      if (lessons.isEmpty) {
        print('No files found for UID: $uid');
        print('This could mean:');
        print('The UID in PocketBase doesn\'t match your current Firebase UID');
        print('No files have been uploaded yet');
        print('There\'s a mismatch in the firebase_uid field');
      }
      
    } catch (e) {
      print('Error loading files: $e');
      _showErrorSnackBar('Error loading files: $e');
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
        withData: true, 
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
    if (selectedFile == null || selectedFile!.bytes == null) {
      _showErrorSnackBar('Please select a valid file first');
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
      String lessonTitle = _generateLessonTitle(selectedFileName ?? 'Untitled');
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;

      if (firebaseUid == null) {
        throw Exception('User not authenticated');
      }

      await _pocketBaseService.uploadLessonFile(
        file: selectedFile!,
        title: lessonTitle,
        firebaseUid: firebaseUid,
        sharedWith: selectedChildren, 
      );

      await _loadParentFiles();

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('File uploaded successfully!');
        
        setState(() {
          selectedChildren.clear();
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading file: $e');
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
          selectedFile = null;
          selectedFileName = null;
        });
      }
    }
  }

  Future<void> _updateFileSharing(LessonFile lesson, List<String> childrenToShareWith) async {
    try {
      await _pocketBaseService.updateFileSharing(lesson.id, childrenToShareWith);
      await _loadParentFiles();
      _showSuccessSnackBar('Sharing updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Error updating sharing: $e');
    }
  }

  String _generateLessonTitle(String fileName) {
    String nameWithoutExt = fileName.split('.').first;

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
      await _loadParentFiles();
      _showSuccessSnackBar('File deleted successfully!');
    } catch (e) {
      _showErrorSnackBar('Error deleting file: $e');
    }
  }

  void _showDeleteDialog(LessonFile lesson) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete File'),
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
              const SizedBox(height: 8),
              Text('Shared with: ${lesson.sharedWith.length} child(ren)'),
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
            if (availableChildren.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSharingDialog(lesson);
                },
                child: const Text('Manage Sharing'),
              ),
          ],
        );
      },
    );
  }

  void _showSharingDialog(LessonFile lesson) {
    final currentlyShared = List<String>.from(lesson.sharedWith);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Share "${lesson.title}"'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableChildren.length,
                  itemBuilder: (context, index) {
                    final child = availableChildren[index];
                    final isSelected = currentlyShared.contains(child['uid']);
                    
                    return CheckboxListTile(
                      title: Text(child['name']),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            currentlyShared.add(child['uid']);
                          } else {
                            currentlyShared.remove(child['uid']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateFileSharing(lesson, currentlyShared);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
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
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Upload New File',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // File selection
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
                                    color: const Color(0xFF2E7D32).withOpacity(0.3),
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
                    
                    // Children selection (only show if there are children available)
                    if (availableChildren.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Share with children:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableChildren.length,
                          itemBuilder: (context, index) {
                            final child = availableChildren[index];
                            final isSelected = selectedChildren.contains(child['uid']);
                            
                            return CheckboxListTile(
                              title: Text(child['name']),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedChildren.add(child['uid']);
                                  } else {
                                    selectedChildren.remove(child['uid']);
                                  }
                                });
                              },
                            );
                          },
                        ),
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
                                    selectedChildren.clear();
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
      body: Column(
        children: [
          const CustomAppbar(),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(child: CustomText.subtitle("My Files")),
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
                                  'No files uploaded yet.\nTap the + button to upload your first file!',
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
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getFileTypeColor(lesson.fileType),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            _getFileTypeIcon(lesson.fileType),
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
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
                                              '${lesson.fileType.toUpperCase()} • ${lesson.formattedFileSize} • Shared with ${lesson.sharedWith.length} child(ren)',
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
                                            } else if (value == 'share') {
                                              _showSharingDialog(lesson);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            if (availableChildren.isNotEmpty)
                                              const PopupMenuItem(
                                                value: 'share',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.share,
                                                      color: Colors.blue,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text('Manage Sharing'),
                                                  ],
                                                ),
                                              ),
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
                                          _showFileInfo(lesson);
                                        },
                                      ),
                                      Divider(
                                        color: Colors.black.withOpacity(0.1),
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

  // Helper methods for file type colors and icons
  Color _getFileTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF': return Colors.red;
      case 'DOC': return Colors.blue;
      case 'PPT': return Colors.orange;
      case 'MP4': return Colors.purple;
      case 'MP3': return Colors.green;
      case 'IMAGE': return Colors.pink;
      default: return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'DOC': return Icons.description;
      case 'PPT': return Icons.slideshow;
      case 'MP4': return Icons.videocam;
      case 'MP3': return Icons.audiotrack;
      case 'IMAGE': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }
}