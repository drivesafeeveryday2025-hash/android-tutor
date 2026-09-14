/// Represents a real-time grammar error detected and evaluated by the AI Tutor.
class GrammarCorrection {
  final bool hasError;
  final String originalSentence;
  final String correctedSentence;
  final String explanation;
  final String errorCategory;
  final String severity;

  const GrammarCorrection({
    required this.hasError,
    required this.originalSentence,
    required this.correctedSentence,
    required this.explanation,
    required this.errorCategory,
    required this.severity,
  });

  factory GrammarCorrection.fromJson(Map<String, dynamic> json) {
    final rawHasError = json['hasError'];
    final bool hasErr = rawHasError == true || rawHasError?.toString().toLowerCase() == 'true';
    return GrammarCorrection(
      hasError: hasErr,
      originalSentence: json['originalSentence']?.toString() ?? '',
      correctedSentence: json['correctedSentence']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      errorCategory: json['errorCategory']?.toString() ?? 'Grammar / Phrasing',
      severity: json['severity']?.toString() ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'hasError': hasError,
        'originalSentence': originalSentence,
        'correctedSentence': correctedSentence,
        'explanation': explanation,
        'errorCategory': errorCategory,
        'severity': severity,
      };
}
