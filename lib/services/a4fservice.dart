import 'dart:convert';
import 'package:http/http.dart' as http;

class A4FService {
  final String _apiKey = 'ddc-a4f-baa45fbc18684a0f80773cd0d2c39459';
  final String _apiUrl = 'https://api.a4f.co/v1/chat/completions';

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
        "model": "provider-2/gpt-3.5-turbo",
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
