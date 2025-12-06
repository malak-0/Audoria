import 'dart:io';
import 'dart:convert';
import 'package:audoria/widgets/page_header.dart';
import 'package:audoria/models/lesson_file_model.dart';
import 'package:audoria/utils/ai_services/text_extraction.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/navigation_services/navigation_helper.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CapturedImageScreen extends StatefulWidget {
  final String? imagePath;
  final Map<String, dynamic>? processedFile;

  const CapturedImageScreen({super.key, this.imagePath, this.processedFile});

  @override
  State<CapturedImageScreen> createState() => _CapturedImageScreenState();
}

class _CapturedImageScreenState extends State<CapturedImageScreen> {
  bool isProcessing = true;
  String processingStatus = 'Extracting text from image...';
  LessonFile? _processedFile;
  String? errorMessage;
  SpeechFeedback? tts;
  String? _imagePath;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    // Wait a bit to ensure previous screen's cleanup is complete
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        tts = SpeechFeedback();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _processImage();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print("=== CAPTURED IMAGE SCREEN DISPOSE ===");
    _isMounted = false;
    // Stop TTS if initialized
    tts?.stop();
    super.dispose();
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
      final allUsers = await FirebaseFirestore.instance.collection('users').get();

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

      final docRef =
          await FirebaseFirestore.instance.collection('files').add(fileData);

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
      }

      await tts?.speak(
        "Image processed successfully! I found text in the image. Would you like me to read it, summarize it, or create a quiz?",
      );
    } catch (e) {
      if (_isMounted) {
        setState(() {
          isProcessing = false;
          errorMessage = e.toString();
        });
      }

      await tts?.speak(
        "Sorry, I couldn't process the image. ${e.toString()}",
      );
    }
  }

  Future<void> _readText() async {
    if (_processedFile?.content == null || _processedFile!.content!.isEmpty) {
      await tts?.speak("Sorry, no text found in the image.");
      return;
    }

    await tts?.stop();
    await tts?.speak("Reading the text now.");
    await Future.delayed(const Duration(milliseconds: 800));
    await tts?.speak(_processedFile!.content!);
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
                    onTap: _readText,
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