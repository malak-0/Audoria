import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrCodeScreen extends StatelessWidget {
  const ScanQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Please scan the QR code on the parent's screen.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const MobileScanner(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
