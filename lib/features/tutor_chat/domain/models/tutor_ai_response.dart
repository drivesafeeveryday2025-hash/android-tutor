import 'grammar_correction.dart';
import 'vocabulary_suggestion.dart';

/// Complete AI response object containing text response, optional grammar corrections,
/// vocabulary suggestions, and overall fluency score.
class TutorAiResponse {
  final String conversationalResponse;
  final GrammarCorrection? grammarCorrection;
  final List<VocabularySuggestion> vocabularySuggestions;
  final int fluencyScore;

  const TutorAiResponse({
    required this.conversationalResponse,
    this.grammarCorrection,
    required this.vocabularySuggestions,
    required this.fluencyScore,
  });

  factory TutorAiResponse.fromJson(Map<String, dynamic> json) {
    GrammarCorrection? correction;
    final rawGc = json['grammarCorrection'];
    if (rawGc != null) {
      if (rawGc is Map) {
        final gcMap = Map<String, dynamic>.from(rawGc);
        if (gcMap['hasError'] == true ||
            gcMap['hasError']?.toString().toLowerCase() == 'true' ||
            (gcMap['correctedSentence']?.toString().isNotEmpty ?? false)) {
          correction = GrammarCorrection.fromJson(gcMap);
        }
      } else if (rawGc is String) {
        final text = rawGc.trim();
        if (text.isNotEmpty &&
            text.toLowerCase() != 'null' &&
            text.toLowerCase() != 'none' &&
            text.toLowerCase() != 'no error') {
          correction = GrammarCorrection(
            hasError: true,
            originalSentence: '',
            correctedSentence: text,
            explanation: 'Suggested natural phrasing for your sentence.',
            errorCategory: 'Grammar / Phrasing',
            severity: 'Medium',
          );
        }
      }
    }

    final vocabList = <VocabularySuggestion>[];
    final rawVocab = json['vocabularySuggestions'];
    if (rawVocab != null && rawVocab is List) {
      for (final item in rawVocab) {
        if (item is Map) {
          vocabList.add(VocabularySuggestion.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String && item.trim().isNotEmpty) {
          vocabList.add(VocabularySuggestion(
            originalWord: '',
            suggestedWord: item.trim(),
            reason: 'Alternative vocabulary to enrich your expression.',
          ));
        }
      }
    }

    String responseText = json['conversationalResponse']?.toString().trim() ?? '';
    if (responseText.isEmpty) {
      responseText = json['response']?.toString().trim() ??
          json['message']?.toString().trim() ??
          json['text']?.toString().trim() ??
          '';
    }
    if (responseText.isEmpty) {
      responseText = 'I am listening! Tell me more.';
    }

    int score = 85;
    final rawScore = json['fluencyScore'];
    if (rawScore is num) {
      score = rawScore.toInt().clamp(30, 100);
    } else if (rawScore != null) {
      final parsed = int.tryParse(rawScore.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed != null) score = parsed.clamp(30, 100);
    }

    return TutorAiResponse(
      conversationalResponse: responseText,
      grammarCorrection: correction,
      vocabularySuggestions: vocabList,
      fluencyScore: score,
    );
  }

  Map<String, dynamic> toJson() => {
        'conversationalResponse': conversationalResponse,
        'grammarCorrection': grammarCorrection?.toJson(),
        'vocabularySuggestions': vocabularySuggestions.map((e) => e.toJson()).toList(),
        'fluencyScore': fluencyScore,
      };
}
