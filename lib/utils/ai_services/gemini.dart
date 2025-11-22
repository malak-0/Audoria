import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = 'AIzaSyBrMOQ8YORnrfen7-5FN3ZfIQlipbhBfLc';
  final String model = 'gemini-2.5-flash';

  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

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
