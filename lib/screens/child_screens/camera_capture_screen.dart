import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:audoria/utils/constants.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/commands_handler.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/listen.dart';
import 'package:audoria/utils/navigation_services/voice_navigation/speak.dart';
import '../../main.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with RouteAware {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  late SpeechFeedback tts;
  late CommandHandler commandHandler;
  final voiceService = VoiceService();
  bool _isVoiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No cameras available");
        return;
      }

      final firstCamera = cameras.first;
      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // Initialize voice system after camera is ready
        _initializeVoiceSystem();
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
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
    await _initializeVoiceSystem();
  }

  Future<void> _initializeVoiceSystem() async {
    if (_isVoiceInitialized) return;

    // Wait a bit to ensure previous screen's cleanup is complete
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

    // Speak instruction after voice service is ready
    if (mounted && _isCameraInitialized) {
      await Future.delayed(const Duration(milliseconds: 500));
      await voiceService.pauseDuringTTS();
      await tts.speak(
        "Camera ready. Say capture to take a photo.",
      ); // Wait for TTS to complete
      await voiceService.resumeAfterTTS();
    }
  }

  Future<void> _handleVoiceCommand(String recognizedText) async {
    final command = recognizedText.toLowerCase().trim();

    // Check if it's the capture command
    if (command == 'capture' || command.contains('capture')) {
      await voiceService.pauseDuringTTS();
      await tts.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      await _captureImage();
      await Future.delayed(const Duration(seconds: 1));
      await voiceService.resumeAfterTTS();
      return;
    }

    // Otherwise, handle as a regular command
    commandHandler.handleCommand(context, 'camera_capture', recognizedText);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _controller == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final picture = await _controller!.takePicture();

      // Navigate to captured image screen with image path
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          'captured_image',
          arguments: {'imagePath': picture.path},
        );
      }
    } catch (e) {
      debugPrint("Capture failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(bgColor),
              ),
              const SizedBox(height: 20),
              Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          SizedBox.expand(child: CameraPreview(_controller!)),

          // Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Capturing Image...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Controls
          if (!_isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Capture Button
                    GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: bgColor,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to capture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
