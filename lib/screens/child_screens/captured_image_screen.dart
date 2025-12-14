import 'dart:io';
import 'dart:convert';
import 'package:audoria/widgets/page_header.dart';
import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/utils/ai_services/text_extraction.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/navigation_services/navigation_helper.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../main.dart';

class CapturedImageScreen extends StatefulWidget {
  final String? imagePath;
  final Map<String, dynamic>? processedFile;

  const CapturedImageScreen({super.key, this.imagePath, this.processedFile});

  @override
  State<CapturedImageScreen> createState() => _CapturedImageScreenState();
}

class _CapturedImageScreenState extends State<CapturedImageScreen>
    with RouteAware {
  bool isProcessing = true;
  String processingStatus = 'Extracting text from image...';
  LessonFile? _processedFile;
  String? errorMessage;
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();
  String? _imagePath;
  bool _isMounted = true;
  bool _isVoiceInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _processImage();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    _reinitializeVoiceAfterReturn();
  }

  Future<void> _reinitializeVoiceAfterReturn() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    _isVoiceInitialized = false;
    if (_processedFile != null) {
      await _initializeVoiceSystem();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _isMounted = false;
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

  Future<void> _initializeVoiceSystem() async {
    if (_isVoiceInitialized || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await voiceService.hardReset();

    tts = SpeechFeedback();
    commandHandler = CommandHandler(tts: tts);
    commandHandler.setVoiceService(voiceService);
    voiceService.autoRestart = false;

    voiceService.onResult = (recognizedText) {
      if (mounted && _processedFile != null) {
        commandHandler.handleCommand(
          context,
          'captured_image',
          recognizedText,
          arguments: _processedFile!.toFullMap(),
        );
      }
    };

    voiceService.autoRestart = true;
    await voiceService.init();
    _isVoiceInitialized = true;

    if (mounted) {
      await voiceService.pauseDuringTTS();
      await tts.speak(
        "Captured image screen. Say summarize, quiz, read, or go back.",
      );
      await voiceService.resumeAfterTTS();
    }
  }

  Future<void> _processImage() async {
    try {
      // Use provided imagePath or get from arguments
      if (widget.imagePath != null) {
        _imagePath = widget.imagePath;
      } else {
        // Get image path from arguments
        final arguments =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        if (arguments != null && arguments['imagePath'] != null) {
          _imagePath = arguments['imagePath'] as String;
        }
      }

      // If we already have processed file from constructor, skip processing
      if (widget.processedFile != null && _imagePath != null) {
        if (_isMounted) {
          setState(() {
            _processedFile = LessonFile.fromMap(widget.processedFile!);
            isProcessing = false;
          });

          // Initialize voice system
          await _initializeVoiceSystem();
        }
        return;
      }

      // Process image if needed
      if (_imagePath == null) {
        throw Exception('No image path provided');
      }

      final imageFile = File(_imagePath!);

      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      // Step 1: Extract text from image
      if (_isMounted) {
        setState(() {
          processingStatus = 'Extracting text from image...';
        });
      }

      final extractedText = await TextExtractionService.extractTextFromImage(
        imageFile,
      );

      if (extractedText.isEmpty) {
        throw Exception('No text found in the image');
      }

      // Step 2: Save to Firebase
      if (_isMounted) {
        setState(() {
          processingStatus = 'Saving to database...';
        });
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get parent UID (the child's parent)
      String? parentUid;
      final allUsers = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (final userDoc in allUsers.docs) {
        final childDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('children')
            .doc(user.uid)
            .get();

        if (childDoc.exists) {
          parentUid = userDoc.id;
          break;
        }
      }

      if (parentUid == null) {
        throw Exception('Parent not found');
      }

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      final fileContentBase64 = base64Encode(imageBytes);

      // Create file document in Firestore
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'captured_image_$timestamp.jpg';

      final fileData = {
        'parentUid': parentUid,
        'children': [user.uid], // Share with this child
        'filename': fileName,
        'title': 'Captured Image ${DateTime.now().toString().split(' ')[0]}',
        'fileType': 'IMAGE',
        'fileSize': imageBytes.length,
        'uploadDate': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'content': extractedText,
        'fileContent': fileContentBase64,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('files')
          .add(fileData);

      // Create LessonFile object
      final lessonFile = LessonFile(
        id: docRef.id,
        title: fileData['title'] as String,
        filename: fileName,
        fileType: 'IMAGE',
        fileSize: imageBytes.length,
        firebaseUid: parentUid,
        sharedWith: [user.uid],
        uploadDate: DateTime.fromMillisecondsSinceEpoch(timestamp),
        content: extractedText,
        fileContent: fileContentBase64,
      );

      // Processing complete
      if (_isMounted) {
        setState(() {
          _processedFile = lessonFile;
          isProcessing = false;
        });

        // Initialize voice system after processing
        await _initializeVoiceSystem();
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          isProcessing = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  // -------- SHOW LOADING SCREEN --------
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show captured image if available
              if (_imagePath != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(_imagePath!),
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 50),
              // Animated Lottie loading
              Lottie.asset(
                'assets/animations/files.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      processingStatus,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Please wait...',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------- SHOW ERROR SCREEN --------
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 30),
                Text(
                  'Processing Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  errorMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------- SHOW MAIN UI --------
  Widget _buildMainScreen() {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header Section
          PageHeader(
            title: _processedFile?.title ?? 'Captured Image',
            subTitle: 'Text Extracted Successfully!',
            imagePath: _imagePath,
          ),

          // -------- GRID VIEW SECTION --------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
                children: [
                  _buildGridCard(
                    title: 'Read text',
                    animation: 'assets/animations/readText.json',
                    onTap: () async {
                      if (_processedFile != null) {
                        await voiceService.pauseDuringTTS();
                        await tts.stop();
                        await commandHandler.handleCommand(
                          context,
                          'captured_image',
                          'read',
                          arguments: _processedFile!.toFullMap(),
                        );
                      }
                    },
                  ),
                  _buildGridCard(
                    title: 'Summary',
                    animation: 'assets/animations/summary.json',
                    onTap: () {
                      if (_processedFile != null) {
                        final fileMap = _processedFile!.toFullMap();
                        NavigationHelper.goTo(
                          context,
                          'summarization',
                          arguments: {'fileData': fileMap},
                        );
                      }
                    },
                  ),
                  _buildGridCard(
                    title: 'Quiz',
                    animation: 'assets/animations/quiz.json',
                    onTap: () {
                      if (_processedFile != null) {
                        final fileMap = _processedFile!.toFullMap();
                        NavigationHelper.goTo(
                          context,
                          'quizzes',
                          arguments: {'fileData': fileMap},
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return _buildLoadingScreen();
    }

    if (errorMessage != null) {
      return _buildErrorScreen();
    }

    return _buildMainScreen();
  }

  // -------- CARD BUILDER --------
  Widget _buildGridCard({
    required String title,
    required String animation,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              SizedBox(
                width: 80,
                height: 80,
                child: Lottie.asset(animation, fit: BoxFit.contain),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
