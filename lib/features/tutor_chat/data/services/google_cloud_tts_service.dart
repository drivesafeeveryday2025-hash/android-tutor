import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';

/// Service responsible for synthesizing natural conversational human speech
/// using Google Cloud Text-to-Speech (Journey and Neural2 voice models).
class GoogleCloudTtsService {
  final http.Client _httpClient;

  GoogleCloudTtsService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Synthesizes text into MP3 audio bytes using Google Cloud Journey Neural TTS.
  /// Returns [Uint8List] on success, or `null` if the API key is missing,
  /// quota is exhausted (429), unauthenticated (401/403), or network fails.
  Future<Uint8List?> synthesizeSpeech({
    required String text,
    String? customApiKey,
    String? customVoice,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : (EnvConfig.googleTtsApiKey.isNotEmpty
            ? EnvConfig.googleTtsApiKey
            : EnvConfig.openAiApiKey);

    if (apiKey.isEmpty) {
      debugPrint('[GoogleCloudTtsService] No Google Cloud TTS API key configured. Skipping neural synthesis.');
      return null;
    }

    final voiceName = (customVoice != null && customVoice.isNotEmpty)
        ? customVoice
        : EnvConfig.googleTtsVoice;

    final uri = Uri.parse(
      'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey',
    );

    final payload = {
      'input': {'text': text},
      'voice': {
        'languageCode': 'en-US',
        'name': voiceName,
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
        'speakingRate': 1.0,
        'pitch': 0.0,
      },
    };

    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'X-Goog-Api-Key': apiKey,
    };

    // If key looks like an OAuth2 token (starts with ya29.), use Bearer header
    if (apiKey.startsWith('ya29.')) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    try {
      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Audio = data['audioContent'] as String?;
        if (base64Audio != null && base64Audio.isNotEmpty) {
          final audioBytes = base64Decode(base64Audio);
          debugPrint(
            '[GoogleCloudTtsService] Successfully synthesized ${audioBytes.length} bytes with voice $voiceName',
          );
          return audioBytes;
        }
      }

      debugPrint(
        '[GoogleCloudTtsService] Synthesis error (HTTP ${response.statusCode}): ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('[GoogleCloudTtsService] Network/Synthesis exception: $e');
      return null;
    }
  }
}
