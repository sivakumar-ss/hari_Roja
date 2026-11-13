import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

class GroqException implements Exception {
  final String message;
  GroqException(this.message);
  @override
  String toString() => message;
}

/// Direct client for the Groq Chat Completions API.
///
/// The assistant is grounded on a JSON snapshot of the user's finances that is
/// injected into the system prompt, so it never has to invent numbers.
class GroqService {
  static const String defaultSystemPrompt =
      'You are "Fin", a warm, practical personal finance advisor for an Indian user. '
      'Use ONLY the verified financial context provided. Never invent amounts or rates. '
      'Answer in 2-4 short paragraphs or a tight bullet list, in the same language the user writes in '
      '(English or Hindi) and keep the tone encouraging. End with a one-line reminder that this is '
      'informational, not licensed financial advice.';

  static Future<http.Response> _post(String model, List<Map<String, String>> messages, Duration timeout) async {
    try {
      return await http
          .post(
            Uri.parse(AppConfig.groqEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.3,
              'max_tokens': 700,
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw GroqException('The AI took too long to respond. Please try again.');
    } catch (e) {
      throw GroqException('Could not reach the AI service. Check your connection.');
    }
  }

  static Future<String> chat({
    required String message,
    required List<Map<String, String>> history,
    Map<String, dynamic>? context,
    String? systemPrompt,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final contextBlock = context == null || context.isEmpty
        ? 'No financial context available yet.'
        : 'Verified financial context (JSON): ${jsonEncode(context)}';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': '${systemPrompt ?? defaultSystemPrompt}\n\n$contextBlock'},
      ...history,
      {'role': 'user', 'content': message},
    ];

    http.Response response = await _post(AppConfig.groqModel, messages, timeout);
    // If the account loses access to the preferred model, retry once with the
    // lighter fallback instead of failing the conversation.
    if ((response.statusCode == 400 || response.statusCode == 404) &&
        response.body.toLowerCase().contains('model')) {
      response = await _post(AppConfig.groqFallbackModel, messages, timeout);
    }

    if (response.statusCode != 200) {
      String detail = '';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] is Map) {
          detail = (decoded['error']['message'] ?? '').toString();
        }
      } catch (_) {
        detail = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
      }
      if (response.statusCode == 401) {
        throw GroqException('The AI API key was rejected. Please check the Groq key.');
      }
      if (response.statusCode == 429) {
        throw GroqException('AI rate limit reached. Please wait a moment and retry.');
      }
      throw GroqException('AI service error (${response.statusCode}). ${detail.isEmpty ? '' : detail}');
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      final content = choices?.isNotEmpty == true
          ? (choices!.first['message']?['content'] ?? '').toString().trim()
          : '';
      if (content.isEmpty) throw GroqException('The AI returned an empty response. Please retry.');
      return content;
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Could not read the AI response.');
    }
  }
}
