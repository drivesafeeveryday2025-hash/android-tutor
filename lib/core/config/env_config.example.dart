/// Template configuration for API keys, default models, and app settings.
/// Copy this file to `env_config.dart` and add your real API keys.
class EnvConfig {
  /// Default OpenAI / Gemini API key (Can be set at runtime or injected)
  /// Replace with your Gemini API key (e.g. AQ.... or AIza....) or OpenAI key (sk-...)
  static String openAiApiKey = '';
  
  /// Selected AI model (Free-tier low demand model)
  static const String defaultModel = 'gemini-3.5-flash-lite';

  /// Default CEFR level for new users
  static const String defaultCefrLevel = 'B1';

  /// Google Cloud Text-to-Speech API Key (optional)
  static String googleTtsApiKey = '';

  /// Google Cloud Journey voice model
  static const String googleTtsVoice = 'en-US-Journey-F';

  /// Default AI Tutor Name
  static const String tutorName = 'Emma';
}

