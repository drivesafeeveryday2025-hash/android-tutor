import '../../domain/models/tutor_ai_response.dart';

/// Abstract contract for AI Language Tutor services.
abstract class IAiTutorService {
  /// Sends a conversation prompt to the AI model and receives a structured response.
  Future<TutorAiResponse> getTutorResponse({
    required String userMessage,
    required String cefrLevel,
    required String scenarioTitle,
    required List<Map<String, String>> conversationHistory,
    String? apiKey,
  });
}
