import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_key_repository.dart';

/// Thrown when there's no key configured yet — callers use this to fall
/// back to non-AI behavior rather than surfacing a scary error.
class GeminiNotConfiguredException implements Exception {}

/// Thrown for anything else that goes wrong (network, quota, bad
/// response) — callers still fall back gracefully; see docs/ARCHITECTURE.md
/// "AI never writes to the local database directly" and the surrounding
/// rule that AI is always a suggestion layered on a working app, never a
/// dependency of it.
class GeminiRequestException implements Exception {
  GeminiRequestException(this.message);
  final String message;

  @override
  String toString() => 'GeminiRequestException: $message';
}

/// Thin wrapper around the Gemini REST API's generateContent endpoint,
/// called directly from the device (see docs/API.md for why: single
/// personal install, no backend hosting needed for v1). Every call asks
/// for JSON output constrained to a schema, so callers get structured
/// data back rather than parsing prose.
class GeminiClient {
  GeminiClient(this._keyRepository);

  final AiKeyRepository _keyRepository;

  static const _model = 'gemini-flash-latest';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<Map<String, dynamic>> generateJson({
    required String prompt,
    required Map<String, dynamic> responseSchema,
  }) async {
    final key = await _keyRepository.getKey();
    if (key == null || key.isEmpty) throw GeminiNotConfiguredException();

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$_endpoint?key=$key'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'responseSchema': responseSchema,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw GeminiRequestException('Could not reach Gemini: $e');
    }

    if (response.statusCode != 200) {
      throw GeminiRequestException(
        'Gemini returned ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiRequestException('Gemini returned no candidates');
    }

    final content = candidates.first['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    final text = parts.first['text'] as String;
    return jsonDecode(text) as Map<String, dynamic>;
  }
}
