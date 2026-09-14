/// Represents a vocabulary recommendation provided by the AI Tutor.
class VocabularySuggestion {
  final String originalWord;
  final String suggestedWord;
  final String reason;

  const VocabularySuggestion({
    required this.originalWord,
    required this.suggestedWord,
    required this.reason,
  });

  factory VocabularySuggestion.fromJson(Map<String, dynamic> json) {
    return VocabularySuggestion(
      originalWord: json['originalWord']?.toString() ?? '',
      suggestedWord: json['suggestedWord']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'originalWord': originalWord,
        'suggestedWord': suggestedWord,
        'reason': reason,
      };
}
