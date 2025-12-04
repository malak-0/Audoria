import 'dart:io';
import 'dart:convert';
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
  const CapturedImageScreen({super.key});

  @override
  State<CapturedImageScreen> createState() => _CapturedImageScreenState();
}

class _CapturedImageScreenState extends State<CapturedImageScreen> {
  bool isProcessing = true;
  String processingStatus = 'Extracting text from image...';
  LessonFile? processedFile;
  String? errorMessage;
  late SpeechFeedback tts;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    tts = SpeechFeedback();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage();
    });
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _processImage() async {
    try {
      // Get image path from arguments
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (arguments == null || arguments['imagePath'] == null) {
        throw Exception('No image path provided');
      }

      imagePath = arguments['imagePath'] as String;
      final imageFile = File(imagePath!);

      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      // Step 1: Extract text from image
      setState(() {
        processingStatus = 'Extracting text from image...';
      });

      final extractedText = await TextExtractionService.extractTextFromImage(
        imageFile,
      );

      if (extractedText.isEmpty) {
        throw Exception('No text found in the image');
      }

      // Step 2: Save to Firebase
      setState(() {
        processingStatus = 'Saving to database...';
      });

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
      processedFile = LessonFile(
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
      setState(() {
        isProcessing = false;
      });

      await tts.speak(
        "Image processed successfully! I found text in the image. Would you like me to read it, summarize it, or create a quiz?",
      );
    } catch (e) {
      setState(() {
        isProcessing = false;
        errorMessage = e.toString();
      });

      await tts.speak(
        "Sorry, I couldn't process the image. ${e.toString()}",
      );
    }
  }

  Future<void> _readText() async {
    if (processedFile?.content == null || processedFile!.content!.isEmpty) {
      await tts.speak("Sorry, no text found in the image.");
      return;
    }

    await tts.stop();
    await tts.speak("Reading the text now.");
    await Future.delayed(const Duration(milliseconds: 800));
    await tts.speak(processedFile!.content!);
  }

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show captured image if available
                if (imagePath != null)
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
                        File(imagePath!),
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

    if (errorMessage != null) {
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

    // Processing complete - show options
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // Image Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          children: [
                            if (imagePath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.file(
                                  File(imagePath!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    'Text Extracted Successfully!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              processedFile?.title ?? 'Captured Image',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // "What would you like to do?" Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: bgColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                'What would you like to do?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Options Cards
                      _buildOptionCard(
                        title: 'Read text',
                        animation: 'assets/animations/readFile.json',
                        onTap: _readText,
                      ),
                      const SizedBox(height: 20),
                      _buildOptionCard(
                        title: 'Summarization',
                        animation: 'assets/animations/summarization.json',
                        onTap: () {
                          final fileMap = processedFile!.toFullMap();
                          NavigationHelper.goTo(
                            context,
                            'summarization',
                            arguments: {'fileData': fileMap},
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildOptionCard(
                        title: 'Quizzes',
                        animation: 'assets/animations/quiz.json',
                        onTap: () {
                          final fileMap = processedFile!.toFullMap();
                          NavigationHelper.goTo(
                            context,
                            'quizzes',
                            arguments: {'fileData': fileMap},
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String animation,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(21.0),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF030303),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Lottie.asset(
                animation,
                width: 120,
                height: 120,
                fit: BoxFit.fitWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
