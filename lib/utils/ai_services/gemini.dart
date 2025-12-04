import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final String apiKey;
  final String model = 'gemini-2.5-flash';

  GeminiService() {
    apiKey = dotenv.get('GEMINI_API_KEY');
  }

  Future<String> generateText(String prompt) async {
    // Use the correct endpoint for the model
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final enhancedPrompt = '''
Give a brief answer (under 50 words) to this question. No markdown, no lists, plain text.

Question: $prompt
''';

    if (kDebugMode) {
      print('Sending to Gemini: $enhancedPrompt');
      print('Using API Key: ${apiKey.substring(0, 10)}...');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": enhancedPrompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 200,
            "topP": 0.8,
            "topK": 40
          }
        }),
      );

      if (kDebugMode) {
        print('Gemini Response Status: ${response.statusCode}');
        print('Gemini Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug the response structure
        if (kDebugMode) {
          print('Full response: $data');
        }

        // Try different response paths
        final candidate = data['candidates']?[0];
        if (candidate != null) {
          final content = candidate['content'];
          if (content != null) {
            final parts = content['parts'];
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                return text.trim();
              }
            }
          }
        }

        // Alternative path
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text.trim();
        }

        throw Exception('No text in response');
        
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Bad request';
        throw Exception('API Error: $errorMsg');
        
      } else if (response.statusCode == 403) {
        throw Exception('API Key invalid or quota exceeded');
        
      } else if (response.statusCode == 404) {
        throw Exception('Model not found. Check model name: $model');
        
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      if (kDebugMode) print('Gemini service error: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection')) {
        return 'Network error: Please check your internet connection';
      } else if (e.toString().contains('403')) {
        return 'API key error: Please check your Gemini API key';
      } else if (e.toString().contains('404')) {
        return 'Model not available. Please check the model name.';
      } else {
        return 'Failed to get response: ${e.toString()}';
      }
    }
  }

  Future<String> summarizeText(String text) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final prompt =
        '''Please provide a clear and concise summary of the following text. 
Focus on the main points, key concepts, and important information. 
Make it easy to understand and well-structured.

Text to summarize:
$text''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } else {
      throw Exception('Failed to generate response: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> generateQuizFromContent(
    String content,
  ) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final prompt =
        '''Based on the following content, generate exactly 5 multiple-choice questions. Each question must have exactly 3 options (A, B, C) and one correct answer.

IMPORTANT: Return ONLY a valid JSON array in this exact format:
[
  {
    "question": "Question text here",
    "options": ["Option A", "Option B", "Option C"],
    "correctAnswerIndex": 0
  },
  ...
]

Where correctAnswerIndex is 0, 1, or 2 (the index of the correct option in the options array).

Content:
$content

Return ONLY the JSON array, no other text:''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final responseText =
          data['candidates'][0]['content']['parts'][0]['text'] as String;

      // Clean the response - remove markdown code blocks if present
      String cleanedText = responseText.trim();
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }
      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }
      cleanedText = cleanedText.trim();

      // Parse JSON
      final List<dynamic> questionsJson = jsonDecode(cleanedText);
      return questionsJson.map((q) => q as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to generate quiz: ${response.body}');
    }
  }
}
