import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class GeminiService {
  late final String apiKey;
  final String model = 'gemini-2.5-flash';

  GeminiService() {
    apiKey = dotenv.get('GEMINI_API_KEY');
  }

  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final enhancedPrompt = '''
      Give a very brief answer to this question. Keep it under 50 words. 
      No markdown, no lists, just plain conversational text.

      Question: $prompt
      ''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': enhancedPrompt},
            ],
          },
        ],
        'generationConfig': {
          'maxOutputTokens': 100, 
          'temperature': 0.7,
        },
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

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Summarize this text: $text'},
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

  Future<String> generateQuiz(String topic) async {
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
              {'text': 'Generate 5 multiple-choice questions about $topic.'},
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
}
