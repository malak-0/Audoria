import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ChildSignupHelper {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final String baseUrl = 'https://us-central1-audoria-f1a49.cloudfunctions.net';

  Future<String> createChildAccount({
    required String email,
    required String password,
    required String name,
    String? age,
    String? grade,
    String? school,
  }) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Parent must be logged in');
      }

      final token = await user.getIdToken();
      
      print('Creating child account for: $email');
      print('Using token: ${token?.substring(0, 20)}...');

      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
        'name': name,
        'age': age,
        'grade': grade,
        'school': school,
      };

      requestBody.removeWhere((key, value) => value == null || value == '');

      final response = await http.post(
        Uri.parse('$baseUrl/createChildAccount'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        print('Child account created successfully: ${data['childUid']}');
        return data['childUid'];
      } else {
        throw Exception(data['error'] ?? 'Failed to create child account');
      }
    } catch (e) {
      print('Error in createChildAccount: $e');
      throw Exception('Failed to create child account: $e');
    }
  }
  //generate token to use in in gererating qr code
  Future<Map<String, dynamic>> generateQRLoginToken(String childUid) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Parent must be logged in');
      }

      final token = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/generateChildLoginToken'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'childUid': childUid,
        }),
      );

      print('QR Token Response status: ${response.statusCode}');
      print('QR Token Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'token': data['token'],
          'expiresAt': data['expiresAt'],
          'qrData': data['qrData'],
        };
      } else {
        throw Exception(data['error'] ?? 'Failed to generate QR token');
      }
    } catch (e) {
      print('Error in generateQRLoginToken: $e');
      throw Exception('Failed to generate QR token: $e');
    }
  }

  //after scaning qr code
  Future<Map<String, dynamic>> validateQRToken(String qrToken) async {
    try {
      print('Sending validation request for token: $qrToken');
      
      final response = await http.post(
        Uri.parse('$baseUrl/validateQRToken'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'token': qrToken,
        }),
      );

      print('Validate QR Response status: ${response.statusCode}');
      print('Validate QR Response body: ${response.body}');

      // Handle different HTTP status codes
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final String? customToken = data['customToken'];
          final String? childUid = data['childUid'];
          
          if (customToken == null) {
            throw Exception('Server returned null customToken');
          }
          return {
            'customToken': customToken,
            'childUid': childUid,
          };
        } else {
          throw Exception(data['error'] ?? 'Failed to validate QR token');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Bad request');
      } else if (response.statusCode == 404) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Invalid token');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in validateQRToken: $e');
      
      if (e is FormatException) {
        throw Exception('Invalid server response. Please check the function URL.');
      } else {
        throw Exception('Failed to validate QR token: $e');
      }
    }
  }
}