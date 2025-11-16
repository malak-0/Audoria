import 'dart:convert';
import 'package:audoria/utils/backend_services/child_signup_helper.dart';
import 'package:audoria/utils/navigation_services/navigation_helper.dart';
import 'package:audoria/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrCodeScreen extends StatefulWidget {
  const ScanQrCodeScreen({super.key});

  @override
  State<ScanQrCodeScreen> createState() => _ScanQrCodeScreenState();
}

class _ScanQrCodeScreenState extends State<ScanQrCodeScreen> {
  final ChildSignupHelper childSignupHelper = ChildSignupHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;
  String _statusMessage = '';

  void _onQRCodeDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null) return;

    _processQRCode(qrData);
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing QR code...';
    });

    try {
      print('Raw QR Data: $qrData');

      String cleanedData = qrData;

      // Handle the JSON string format
      if (qrData.startsWith('"') && qrData.endsWith('"')) {
        cleanedData = qrData.substring(1, qrData.length - 1);
      }

      // Replace escaped characters
      cleanedData = cleanedData.replaceAll(r'\"', '"');

      print('Cleaned QR Data: $cleanedData');

      final decodedData = json.decode(cleanedData);
      print('Decoded QR Data: $decodedData');

      if (decodedData is! Map<String, dynamic> ||
          !decodedData.containsKey('token')) {
        throw Exception('Invalid QR code format. Expected token field.');
      }

      final String token = decodedData['token'];
      print('Extracted token: $token');

      if (token.isEmpty) {
        throw Exception('QR code missing authentication token');
      }

      setState(() {
        _statusMessage = 'Validating token...';
      });

      print('Calling validateQRToken with token: $token');
      final result = await childSignupHelper.validateQRToken(token);

      print('Validation result: $result');
      final String? customToken = result['customToken'];
      if (customToken == null || customToken.isEmpty) {
        throw Exception('No authentication token received from server');
      }

      setState(() {
        _statusMessage = 'Signing in...';
      });

      print('Signing in with custom token...');
      final userCredential = await _auth.signInWithCustomToken(customToken);
      print('Sign in successful: ${userCredential.user?.uid}');

      setState(() {
        _statusMessage = 'Login successful! Redirecting...';
      });

      // Add a small delay to show success message
      await Future.delayed(const Duration(seconds: 1));

      NavigationHelper.replaceWith(context, "child_home");
    } catch (e) {
      print('QR Login Error: $e');
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });

      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _statusMessage = "Please scan the QR code on the parent's screen.";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Header Section
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: textColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: textColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner, color: bgColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'QR Scanner',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // Instruction Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.qr_code_2_outlined,
                          color: bgColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusMessage.isEmpty
                            ? "Scan QR Code"
                            : _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (_statusMessage.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Please scan the QR code displayed on the parent's screen to log in.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: textColor.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // QR Scanner Container
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: textColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: _isProcessing ? bgColor : Colors.grey.shade300,
                      width: _isProcessing ? 4 : 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: cameraController,
                          onDetect: _onQRCodeDetect,
                        ),
                        // Processing overlay
                        if (_isProcessing)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Helper Text
                if (!_isProcessing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: textColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Position the QR code within the frame',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
