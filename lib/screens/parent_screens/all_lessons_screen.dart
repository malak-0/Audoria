import 'package:audoria/utils/backend_services/firestore_file_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../models/lesson_file_model.dart';
import '../../utils/constants.dart';

class AllLessonsScreen extends StatefulWidget {
  const AllLessonsScreen({super.key});

  @override
  State<AllLessonsScreen> createState() => _AllLessonsScreenState();
}

class _AllLessonsScreenState extends State<AllLessonsScreen> {
  final FirestoreFileService _firestoreFileService = FirestoreFileService();
  final user = FirebaseAuth.instance.currentUser;
  String? get uid => user?.uid;
  List<LessonFile> lessons = [];
  bool isLoading = true;

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
    if (uid == null) return;

    try {
      // Get children from the parent's subcollection
      final childrenSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .get();

      List<Map<String, dynamic>> childrenList = childrenSnapshot.docs.map((
        doc,
      ) {
        final data = doc.data();
        return {
          'uid': doc.id, // Child UID
          'name': data['name'] ?? 'Unknown',
        };
      }).toList();

      setState(() {
        availableChildren = childrenList;
      });
    } catch (e) {
      setState(() {
        availableChildren = [];
      });
    }
  }

  Future<void> _initializeData() async {
    try {
      if (uid != null) {
        await _loadParentFiles();
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
      final filesData = await _firestoreFileService.getFilesByParent(uid!);

      List<LessonFile> loadedLessons = [];

      for (var fileData in filesData) {
        try {
          final lesson = LessonFile.fromFirestore(fileData);
          loadedLessons.add(lesson);
        } catch (e) {
          // Skip invalid files
        }
      }

      setState(() {
        lessons = loadedLessons;
      });
    } catch (e) {
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

    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    setState(() {
      isUploading = true;
    });

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Uploading file...\nExtracting text...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Inter'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      await _firestoreFileService.uploadFile(
        file: selectedFile!,
        parentUid: firebaseUid,
        children: selectedChildren,
      );

      // Clear selection before reloading
      setState(() {
        selectedChildren.clear();
        selectedFile = null;
        selectedFileName = null;
      });

      // Reload files after upload
      await _loadParentFiles();

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        // Close upload dialog
        Navigator.pop(context);
        _showSuccessSnackBar('File uploaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        _showErrorSnackBar('Error uploading file: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> _updateFileSharing(
    LessonFile lesson,
    List<String> childrenToShareWith,
  ) async {
    try {
      await _firestoreFileService.updateFileSharing(
        lesson.id,
        childrenToShareWith,
      );
      await _loadParentFiles();
      _showSuccessSnackBar('Sharing updated successfully!');
    } catch (e) {
      _showErrorSnackBar('Error updating sharing: $e');
    }
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
    try {
      await _firestoreFileService.deleteFile(lesson.id);
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
                        child: Material(
                          color: Colors.transparent,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableChildren.length,
                            itemBuilder: (context, index) {
                              final child = availableChildren[index];
                              final isSelected = selectedChildren.contains(
                                child['uid'],
                              );

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
      backgroundColor: bgColor,
      body: Column(
        children: [
          const CustomAppbar(),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.folder, color: textColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'My Files',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${lessons.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 20),
                                Text(
                                  'Loading your files...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : lessons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: textColor.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.upload_file,
                                    size: 64,
                                    color: textColor.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No files uploaded yet',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to upload your first file',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildFileCard(lesson),
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
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [textColor, textColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: textColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showUploadDialog,
            borderRadius: BorderRadius.circular(32),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildFileCard(LessonFile lesson) {
    final fileColor = _getFileTypeColor(lesson.fileType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFileInfo(lesson),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // File Type Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [fileColor, fileColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: fileColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getFileTypeIcon(lesson.fileType),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: textColor.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson.formattedUploadDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: fileColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lesson.fileType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: fileColor,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description,
                              size: 14,
                              color: textColor.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lesson.formattedFileSize,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: textColor.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${lesson.sharedWith.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Menu Button
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(lesson);
                  } else if (value == 'share') {
                    _showSharingDialog(lesson);
                  }
                },
                itemBuilder: (context) => [
                  if (availableChildren.isNotEmpty)
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: bgColor, size: 20),
                          const SizedBox(width: 12),
                          const Text('Manage Sharing'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        const Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for file type colors and icons
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
}
