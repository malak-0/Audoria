import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  int _countdown = 0;

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
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _controller == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _countdown = 5;
    });

    try {
      final picture = await _controller!.takePicture();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image captured: ${picture.path}')),
      );

      // Countdown for 10 seconds
      for (int i = 5; i > 0; i--) {
        if (!mounted) return;
        setState(() {
          _countdown = i;
        });
        await Future.delayed(const Duration(seconds: 1));
      }

      // Navigate to captured image screen
      if (mounted) {
        Navigator.pushNamed(context, 'captured_image');
      }
    } catch (e) {
      debugPrint("Capture failed: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      setState(() {
        _isProcessing = false;
        _countdown = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CameraPreview(_controller!),
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing image...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Navigating in $_countdown seconds',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Capture button
          if (!_isProcessing)
            Positioned(
              bottom: 40,
              child: GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      "capture",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
