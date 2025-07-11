import 'dart:convert';
import 'package:http/http.dart' as http;

class A4FService {
  final String _apiKey = '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';
  final String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> generateMCQs(String input, {bool isTopicOnly = false}) async {
    final promptText = isTopicOnly
        ? "Generate 5 multiple choice questions (MCQs) from the topic: '$input'. "
          "Each question must have 4 options (A, B, C, D) and indicate the correct answer."
        : "Generate 5 multiple choice questions (MCQs) from the following text. "
          "Each question must have 4 options (A, B, C, D) and indicate the correct answer.\n\n$input";

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "openai/gpt-4.1-mini",
        "messages": [
          {
            "role": "system",
            "content":
                "You are an AI assistant that creates high-quality multiple choice questions (MCQs) from educational text."
          },
          {
            "role": "user",
            "content": promptText,
          }
        ],
        "temperature": 0.7,
        "max_tokens": 800
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('A4F API Error ${response.statusCode}: ${response.body}');
    }
  }
}
