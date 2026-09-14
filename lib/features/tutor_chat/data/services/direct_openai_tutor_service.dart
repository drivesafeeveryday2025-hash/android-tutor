import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env_config.dart';
import '../../domain/models/grammar_correction.dart';
import '../../domain/models/tutor_ai_response.dart';
import '../../domain/models/vocabulary_suggestion.dart';
import 'i_ai_tutor_service.dart';

/// Client-side implementation that calls OpenAI Chat Completion API directly using HTTP.
class DirectOpenAiTutorService implements IAiTutorService {
  final http.Client _httpClient;

  DirectOpenAiTutorService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<TutorAiResponse> getTutorResponse({
    required String userMessage,
    required String cefrLevel,
    required String scenarioTitle,
    required List<Map<String, String>> conversationHistory,
    String? apiKey,
  }) async {
    final key = (apiKey != null && apiKey.isNotEmpty) ? apiKey : EnvConfig.openAiApiKey;

    // If no key is configured yet, return intelligent mock tutor response for UI testing
    if (key.isEmpty) {
      return _generateMockResponse(userMessage, cefrLevel);
    }

    final isGemini = key.startsWith('AQ.') ||
        key.startsWith('AIza') ||
        EnvConfig.defaultModel.toLowerCase().contains('gemini');

    if (isGemini) {
      return _callGemini(
        key: key,
        userMessage: userMessage,
        cefrLevel: cefrLevel,
        scenarioTitle: scenarioTitle,
        conversationHistory: conversationHistory,
      );
    }

    final systemPrompt = '''
You are Emma, a friendly, patient, and encouraging AI English tutor.
Your mission is to converse with the user in natural English while helping them improve their grammar, vocabulary, and structure.

CONVERSATION RULES:
1. User CEFR Level: $cefrLevel. Adjust your vocabulary and sentence length accordingly.
2. Active Topic: $scenarioTitle. Keep the dialogue relevant to this scenario.
3. Always end your response with an engaging question to keep conversation flowing.
4. Converse naturally and adjust response length dynamically: 2-3 sentences for simple greetings, or 3-6 sentences with richer context, thoughts, and elaboration when exploring topics, stories, or activities.

CRITICAL: Respond ONLY in valid JSON matching this schema:
{
  "conversationalResponse": "That sounds like a great plan! What time will you go?",
  "grammarCorrection": {
    "hasError": true,
    "originalSentence": "I was go to store yesterday.",
    "correctedSentence": "I went to the store yesterday.",
    "explanation": "Use past simple 'went' instead of 'was go', and add the article 'the'.",
    "errorCategory": "Verb Tense / Article",
    "severity": "Medium"
  },
  "vocabularySuggestions": [
    {
      "originalWord": "go",
      "suggestedWord": "headed / visited",
      "reason": "Improves sentence variety."
    }
  ],
  "fluencyScore": 80
}
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Append history
    messages.addAll(conversationHistory);
    messages.add({'role': 'user', 'content': userMessage});

    try {
      final response = await _httpClient.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': EnvConfig.defaultModel,
          'temperature': 0.7,
          'response_format': {'type': 'json_object'},
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final contentStr = data['choices'][0]['message']['content'] as String;
        final jsonContent = jsonDecode(contentStr) as Map<String, dynamic>;
        return TutorAiResponse.fromJson(jsonContent);
      } else {
        throw Exception('OpenAI API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Fallback to mock on error so app stays responsive
      return _generateMockResponse(userMessage, cefrLevel);
    }
  }

  /// Calls Google Gemini API directly using the user's Gemini API key.
  Future<TutorAiResponse> _callGemini({
    required String key,
    required String userMessage,
    required String cefrLevel,
    required String scenarioTitle,
    required List<Map<String, String>> conversationHistory,
  }) async {
    final StringBuffer historyBuffer = StringBuffer();
    for (final m in conversationHistory) {
      final role = m['role'] == 'user' ? 'User' : 'Emma';
      final content = m['content'] ?? '';
      if (content.trim().isNotEmpty && content.trim() != userMessage.trim()) {
        historyBuffer.writeln('$role: $content');
      }
    }
    final historyContext = historyBuffer.isEmpty
        ? ""
        : "\nPrior Conversation History:\n${historyBuffer.toString()}\n";

    final prompt = '''
You are Emma, an intelligent, friendly, patient, and encouraging AI English tutor.
User CEFR Level: $cefrLevel. Active Topic: $scenarioTitle.
$historyContext
Latest message from user: "$userMessage"

Instructions:
1. Remember everything said previously in the Prior Conversation History and refer back to it naturally when appropriate.
2. Converse naturally with rich detail, adjusting response length dynamically according to the conversation:
   - For simple greetings or brief statements, reply warmly in 2-3 sentences.
   - For discussions, stories, opinions, questions, or shared activities, provide a richer, more engaging response (typically 3 to 6 descriptive sentences) offering relevant insights, friendly thoughts, or relatable context.
3. If the user makes any grammatical, spelling, or vocabulary errors, pinpoint it in grammarCorrection.
4. Suggest 1-2 vocabulary alternatives to enrich their English expression.
5. Rate their sentence fluency score from 50 to 100.
6. Always end with an engaging question to keep the conversation going.

CRITICAL: Return ONLY valid JSON without backticks matching this schema:
{
  "conversationalResponse": "Emma's conversational response here",
  "grammarCorrection": {
    "hasError": true,
    "originalSentence": "user's error sentence",
    "correctedSentence": "corrected version",
    "explanation": "concise grammar explanation",
    "errorCategory": "Tense / Spelling / Preposition",
    "severity": "Low / Medium / High"
  },
  "vocabularySuggestions": [
    {
      "originalWord": "word from user",
      "suggestedWord": "more natural or advanced alternative",
      "reason": "why this improves expression"
    }
  ],
  "fluencyScore": 85
}
(If there is no grammar or spelling error, set grammarCorrection to null).
''';

    // Priority: Low-demand free-tier model (gemini-3.5-flash-lite).
    // Only if it fails, try the secondary lightweight fallback (gemini-3.1-flash-lite-preview).
    final candidateModels = <String>[
      EnvConfig.defaultModel,
      if (EnvConfig.defaultModel != 'gemini-3.1-flash-lite-preview')
        'gemini-3.1-flash-lite-preview',
    ];

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
      }
    });

    for (final modelName in candidateModels) {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key');
      try {
        final response = await _httpClient.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>;
            final parts = content['parts'] as List;
            if (parts.isNotEmpty) {
              String text = parts[0]['text'] as String;
              text = text.trim();
              if (text.startsWith('```json')) {
                text = text.substring(7);
              } else if (text.startsWith('```')) {
                text = text.substring(3);
              }
              if (text.endsWith('```')) {
                text = text.substring(0, text.length - 3);
              }
              text = text.trim();
              try {
                final jsonContent = jsonDecode(text) as Map<String, dynamic>;
                return TutorAiResponse.fromJson(jsonContent);
              } catch (parseErr) {
                debugPrint('[DirectOpenAiTutorService] Fallback JSON parse on $modelName: $parseErr');
                return TutorAiResponse(
                  conversationalResponse: text.replaceAll(RegExp(r'[\{\}\[\]"]'), ' ').trim(),
                  grammarCorrection: null,
                  vocabularySuggestions: const [],
                  fluencyScore: 85,
                );
              }
            }
          }
        }
        debugPrint('[DirectOpenAiTutorService] Model $modelName returned ${response.statusCode}: ${response.body}');
      } catch (e) {
        debugPrint('[DirectOpenAiTutorService] Error calling model $modelName: $e');
      }
    }

    debugPrint('[DirectOpenAiTutorService] All candidate Gemini models failed. Falling back to offline response.');
    return _generateMockResponse(userMessage, cefrLevel);
  }

  /// Mock generator for instant preview & testing without API key
  TutorAiResponse _generateMockResponse(String input, String cefr) {
    final trimmed = input.trim();
    final lower = trimmed.toLowerCase();

    // 1. Grammar error detection
    bool hasError = false;
    String original = trimmed;
    String corrected = trimmed;
    String explanation = "";
    String category = "Grammar";

    if (lower.contains('was go')) {
      hasError = true;
      corrected = trimmed.replaceAll(RegExp(r'was go', caseSensitive: false), 'went');
      explanation = "Use 'went' (past simple) instead of 'was go'.";
      category = "Verb Tense";
    } else if (lower.contains('buyed')) {
      hasError = true;
      corrected = trimmed.replaceAll(RegExp(r'buyed', caseSensitive: false), 'bought');
      explanation = "'Buy' is an irregular verb. The past form is 'bought'.";
      category = "Irregular Verb";
    } else if (lower.contains('i am agree')) {
      hasError = true;
      corrected = trimmed.replaceAll(RegExp(r'i am agree', caseSensitive: false), 'I agree');
      explanation = "In English, 'agree' is a verb. Say 'I agree', not 'I am agree'.";
      category = "Subject-Verb Agreement";
    } else if (lower.contains('she go ') || lower.contains('he go ')) {
      hasError = true;
      corrected = trimmed.replaceAll(RegExp(r'\bgo\b', caseSensitive: false), 'goes');
      explanation = "Third-person singular present takes '-es' ('she goes', 'he goes').";
      category = "Subject-Verb Agreement";
    }

    // 2. Contextual Conversational Replies
    String reply;
    List<VocabularySuggestion> vocab = [];

    if (lower == 'hi' || lower == 'hello' || lower.startsWith('hi ') || lower.startsWith('hello ')) {
      reply = "Hello! It's wonderful to practice with you today. How are you doing, and what would you like to talk about?";
      vocab = [
        const VocabularySuggestion(
          originalWord: "hi",
          suggestedWord: "Greetings / Good day",
          reason: "Useful formal alternatives for different contexts.",
        ),
      ];
    } else if (lower.contains('topic') || lower.contains('what can we talk') || lower.contains('suggest')) {
      reply = "We have plenty of great topics! For example: 1) Ordering at a cafe, 2) Preparing for a job interview, 3) Describing your hometown, or 4) Weekend travel. Which one sounds fun to you?";
      vocab = [
        const VocabularySuggestion(
          originalWord: "topic",
          suggestedWord: "subject / theme",
          reason: "Enriches conversational variety.",
        ),
      ];
    } else if (lower.contains('anyone there') || lower.contains('anyone here') || lower.contains('hello?')) {
      reply = "I'm right here with you! Ready whenever you are. What's on your mind today?";
    } else if (lower.contains('name') || lower.contains('who are you')) {
      reply = "I'm Emma, your personal AI English tutor! You can tell me anything about your day or practice speaking with me.";
    } else if (hasError) {
      reply = "I understand what you meant! A more natural phrasing is: '$corrected'. How did that go?";
    } else {
      final dynamicOptions = [
        "That's really interesting! Could you tell me more about how that went?",
        "I see! How do you usually feel when that happens?",
        "Sounds great! What are you planning to do next about that?",
        "Thanks for sharing that with me! How long have you been interested in this?",
      ];
      final index = (trimmed.length) % dynamicOptions.length;
      reply = dynamicOptions[index];
      vocab = [
        const VocabularySuggestion(
          originalWord: "good",
          suggestedWord: "delightful / fantastic",
          reason: "Adds vivid description to your sentences.",
        ),
      ];
    }

    return TutorAiResponse(
      conversationalResponse: reply,
      grammarCorrection: hasError
          ? GrammarCorrection(
              hasError: true,
              originalSentence: original,
              correctedSentence: corrected,
              explanation: explanation,
              errorCategory: category,
              severity: "Medium",
            )
          : null,
      vocabularySuggestions: vocab,
      fluencyScore: hasError ? 75 : 94,
    );
  }
}
