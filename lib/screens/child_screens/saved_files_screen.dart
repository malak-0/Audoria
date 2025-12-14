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
import '../../main.dart';

class SavedFilesScreen extends StatefulWidget {
  const SavedFilesScreen({super.key});

  @override
  State<SavedFilesScreen> createState() => _SavedFilesScreenState();
}

class _SavedFilesScreenState extends State<SavedFilesScreen>
    with WidgetsBindingObserver, RouteAware {
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();
  List<LessonFile> _files = [];
  bool _isVoiceInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndInitialize();
  }

  Future<void> _loadAndInitialize() async {
    // Load files first
    _files = await _loadFilesForChild();
    if (mounted) {
      setState(() {}); // Update UI with loaded files
    }
    // Then initialize voice system
    await _initializeVoiceSystem();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isVoiceInitialized) {
      // Re-initialize if needed when app comes back to foreground
      _initializeVoiceSystem();
    }
  }

  @override
  void didPopNext() {
    _reinitializeVoiceAfterReturn();
  }

  Future<void> _reinitializeVoiceAfterReturn() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _files = await _loadFilesForChild();
    _isVoiceInitialized = false;
    await _initializeVoiceSystem();
  }

  Future<void> _initializeVoiceSystem() async {
    if (_isVoiceInitialized) {
      if (!voiceService.isActive) {
        _isVoiceInitialized = false;
      } else {
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Hard reset voice service to ensure clean state
    await voiceService.hardReset();

    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    commandHandler.setVoiceService(voiceService);
    voiceService.autoRestart = false;

    voiceService.onResult = (recognizedText) {
      if (mounted) {
        _handleVoiceCommand(recognizedText);
      }
    };

    voiceService.autoRestart = true;

    await voiceService.init();
    _isVoiceInitialized = true;

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      await voiceService.pauseDuringTTS();
      await _announceFiles();
      await voiceService.resumeAfterTTS();
    }
  }

  Future<void> _announceFiles() async {
    if (_files.isEmpty) {
      await tts.speak(
        "Lessons screen. No files available. Ask your parent to share some lessons.",
      );
    } else if (_files.length == 1) {
      await tts.speak(
        "Lessons screen. You have 1 file: ${_files[0].title}. Say the file name to open it.",
      );
    } else if (_files.length <= 3) {
      final fileNames = _files.map((f) => f.title).join(', ');
      await tts.speak(
        "Lessons screen. You have ${_files.length} files: $fileNames. Say a file name to open it.",
      );
    } else {
      final firstThree = _files.take(3).map((f) => f.title).join(', ');
      await tts.speak(
        "Lessons screen. You have ${_files.length} files. First few are: $firstThree. Say a file name to open it.",
      );
    }
  }

  Future<void> _handleVoiceCommand(String recognizedText) async {
    final command = recognizedText.toLowerCase().trim();

    // First check if it matches a file name
    final matchedFile = _findFileByName(command);
    if (matchedFile != null) {
      try {
        // Pause voice service BEFORE TTS
        await voiceService.pauseDuringTTS();
        await tts.stop();
        await Future.delayed(const Duration(milliseconds: 200));

        print(
          "🎯 Matched file: ${matchedFile.title}, preparing to navigate...",
        );

        final fileMap = matchedFile.toFullMap();
        print("📦 File map created with ${fileMap.keys.length} keys");

        if (!mounted) {
          print("❌ Widget not mounted, cannot navigate");
          await voiceService.resumeAfterTTS();
          return;
        }

        print("🚀 Navigating to single_file_screen...");

        // Navigate FIRST, then speak
        Navigator.pushNamed(
              context,
              'single_file_screen',
              arguments: {'fileData': fileMap},
            )
            .then((_) {
              print("✅ Navigation completed successfully");
            })
            .catchError((error) {
              print("❌ Navigation error: $error");
            });

        // Small delay to ensure navigation starts
        await Future.delayed(const Duration(milliseconds: 300));

        // Speak after navigation has started
        await tts.speak("Opening ${matchedFile.title}");

        print("🔊 TTS completed");
      } catch (e) {
        print("❌ Error in _handleVoiceCommand: $e");
        await voiceService.resumeAfterTTS();
      }

      // Don't resume here - we're navigating away, so the new screen will handle voice
      return;
    }

    // Otherwise, handle as a regular command
    commandHandler.handleCommand(context, 'saved_files', recognizedText);
  }

  LessonFile? _findFileByName(String command) {
    // Try exact match first
    for (var file in _files) {
      if (file.title.toLowerCase().trim() == command) {
        return file;
      }
    }

    // Try partial match (contains)
    for (var file in _files) {
      final fileTitleLower = file.title.toLowerCase().trim();
      if (fileTitleLower.contains(command) ||
          command.contains(fileTitleLower)) {
        return file;
      }
    }

    // Try word-by-word matching
    final commandWords = command.split(' ').where((w) => w.length > 2).toList();
    if (commandWords.isNotEmpty) {
      for (var file in _files) {
        final fileTitleLower = file.title.toLowerCase();
        final allWordsMatch = commandWords.every(
          (word) => fileTitleLower.contains(word),
        );
        if (allWordsMatch) {
          return file;
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _isVoiceInitialized = false;
    try {
      tts.stop();
    } catch (e) {}
    try {
      voiceService.uninitialize();
    } catch (e) {}
    try {
      commandHandler.dispose();
    } catch (e) {}
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
                  return Center(
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
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading files',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
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
                            Icons.folder_open,
                            size: 64,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No files shared yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Files shared by your parent will appear here',
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final files = snapshot.data!;

                // Update files list
                if (files.isNotEmpty) {
                  _files = files;
                } else {
                  _files = [];
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.folder,
                              color: textColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'My Lessons',
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
                              '${files.length}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: files.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFileCard(files[index]),
                        ),
                      ),
                    ),
                  ],
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
    final fileColor = _getFileTypeColor(file.fileType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final fileMap = file.toFullMap();
          NavigationHelper.goTo(
            context,
            'single_file_screen',
            arguments: {'fileData': fileMap},
          );
        },
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
                  _getFileTypeIcon(file.fileType),
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
                      file.title,
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
                          file.formattedUploadDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
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
                            file.fileType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: fileColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.description,
                          size: 14,
                          color: textColor.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          file.formattedFileSize,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: textColor.withOpacity(0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // File type color and icon methods
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
