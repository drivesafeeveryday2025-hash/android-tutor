import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/config/env_config.dart';
import '../../data/services/direct_openai_tutor_service.dart';
import '../../data/services/google_cloud_tts_service.dart';
import '../../data/services/i_ai_tutor_service.dart';
import '../../domain/models/grammar_correction.dart';
import '../../domain/models/tutor_ai_response.dart';

class ChatMessageItem {
  final String text;
  final bool isUser;
  final GrammarCorrection? correction;
  final DateTime timestamp;

  ChatMessageItem({
    required this.text,
    required this.isUser,
    this.correction,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatState {
  final List<ChatMessageItem> messages;
  final bool isLoading;
  final bool isRecording;
  final bool isPlayingTts;
  final String cefrLevel;
  final String scenarioTitle;
  final int fluencyScore;
  final String? errorMessage;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.isPlayingTts = false,
    this.cefrLevel = 'B1',
    this.scenarioTitle = 'Free Conversation',
    this.fluencyScore = 88,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessageItem>? messages,
    bool? isLoading,
    bool? isRecording,
    bool? isPlayingTts,
    String? cefrLevel,
    String? scenarioTitle,
    int? fluencyScore,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      isPlayingTts: isPlayingTts ?? this.isPlayingTts,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      scenarioTitle: scenarioTitle ?? this.scenarioTitle,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      errorMessage: errorMessage,
    );
  }
}

final aiTutorServiceProvider = Provider<IAiTutorService>((ref) {
  return DirectOpenAiTutorService();
});

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final aiService = ref.watch(aiTutorServiceProvider);
  return ChatController(aiService: aiService);
});

class ChatController extends StateNotifier<ChatState> {
  final IAiTutorService aiService;
  final GoogleCloudTtsService _googleTtsService = GoogleCloudTtsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  StreamSubscription? _playerStateSubscription;

  ChatController({required this.aiService}) : super(ChatState()) {
    _initTts();
    _sendInitialGreeting();
  }

  void _initTts() async {
    try {
      _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((playerState) {
        if (!mounted) return;
        if (playerState == PlayerState.playing) {
          state = state.copyWith(isPlayingTts: true);
        } else if (playerState == PlayerState.completed ||
            playerState == PlayerState.stopped ||
            playerState == PlayerState.paused) {
          state = state.copyWith(isPlayingTts: false);
        }
      });

      _tts.setStartHandler(() {
        if (mounted) state = state.copyWith(isPlayingTts: true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) state = state.copyWith(isPlayingTts: false);
      });
      _tts.setCancelHandler(() {
        if (mounted) state = state.copyWith(isPlayingTts: false);
      });
      _tts.setErrorHandler((msg) {
        if (mounted) state = state.copyWith(isPlayingTts: false);
      });

      await _tts.setLanguage("en-US");
      // On Web (W3C SpeechSynthesis), rate 1.0 is normal speed (0.92 is warm/clear).
      // On Android native TTS, 0.5 is normal speed.
      await _tts.setSpeechRate(kIsWeb ? 0.92 : 0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Attempt initial voice configuration
      await _ensureNaturalVoiceSelected();
    } catch (_) {
      // TTS engine not ready or voice data missing
    }
  }

  bool _voiceConfigured = false;

  /// Dynamically queries available system voices and strictly selects a female English voice for Chole.
  /// Explicitly filters out male voices (e.g. Google US English, David, Mark, Guy)
  /// and prioritizes natural female online voices, Google UK English Female, or Microsoft Zira.
  Future<void> _ensureNaturalVoiceSelected() async {
    if (_voiceConfigured) return;
    try {
      dynamic voices = await _tts.getVoices;
      if (voices is! List || voices.isEmpty) {
        // In Chrome Web, window.speechSynthesis.getVoices() is initially empty.
        // Wait briefly for the browser to populate voices.
        await Future.delayed(const Duration(milliseconds: 350));
        voices = await _tts.getVoices;
      }

      if (voices is List && voices.isNotEmpty) {
        dynamic preferredVoice;
        int bestScore = -1;

        for (final v in voices) {
          if (v is Map) {
            final name = (v['name'] ?? '').toString().toLowerCase();
            final locale = (v['locale'] ?? '').toString().toLowerCase();
            final gender = (v['gender'] ?? '').toString().toLowerCase();

            // 1. Strict English check: reject non-English voices (e.g. Hanhan, Yating, etc.)
            final isEnglish = locale.contains('en-us') ||
                locale.contains('en_us') ||
                locale.contains('en-gb') ||
                locale.startsWith('en') ||
                name.contains('english');
            if (!isEnglish) continue;

            // 2. Strict Male Exclusion: NEVER assign a male voice to Chole
            // Note: In Chrome, 'Google US English' is a male voice!
            final isMale = gender == 'male' ||
                name.contains('google us english') ||
                name.contains('google uk english male') ||
                name.contains('david') ||
                name.contains('mark') ||
                name.contains('guy') ||
                name.contains('george') ||
                name.contains('richard') ||
                name.contains('james') ||
                name.contains('stefan') ||
                name.contains('paul') ||
                name.contains(' male') ||
                name.contains('(male)');
            if (isMale) continue;

            // 3. Female Scoring System
            int score = 10; // Default baseline for non-male English voice

            // Tier 1: High-definition Natural / Neural Online Female Voice (Edge / Cloud)
            final isNatural = name.contains('natural') || name.contains('neural') || name.contains('online');
            final hasFemaleName = name.contains('female') ||
                name.contains('jenny') ||
                name.contains('aria') ||
                name.contains('chloe') ||
                name.contains('lily') ||
                name.contains('emma') ||
                name.contains('ava') ||
                name.contains('ana') ||
                name.contains('zira') ||
                name.contains('samantha');

            if (isNatural && hasFemaleName) {
              score = 100;
            } else if (name.contains('google uk english female') || (name.contains('google') && name.contains('female'))) {
              // Tier 2: Chrome's built-in female voice
              score = 90;
            } else if (name.contains('zira')) {
              // Tier 3: Windows pre-installed female voice (Microsoft Zira Desktop)
              score = 80;
            } else if (hasFemaleName || gender == 'female') {
              // Tier 4: Other named female voices (Samantha, Victoria, Karen, etc.)
              score = 70;
            } else if (isNatural) {
              // Tier 5: Natural online voice that wasn't flagged as male
              score = 50;
            }

            if (score > bestScore) {
              bestScore = score;
              preferredVoice = v;
            }
          }
        }

        if (preferredVoice != null && preferredVoice is Map) {
          final voiceMap = Map<String, String>.from(
            preferredVoice.map((key, value) => MapEntry(key.toString(), value.toString())),
          );
          await _tts.setVoice(voiceMap);
          _voiceConfigured = true;
          debugPrint('[ChatController] Selected Female English voice: ${voiceMap['name']} (${voiceMap['locale']}) with score $bestScore');
        }
      }
    } catch (e) {
      debugPrint('[ChatController] Error configuring natural voice: $e');
    }
  }

  void _sendInitialGreeting() {
    state = state.copyWith(
      messages: [
        ChatMessageItem(
          text: "Hi there! I'm ${EnvConfig.tutorName}, your English tutor. What would you like to talk about today?",
          isUser: false,
        ),
      ],
    );
  }

  String _lastSentText = '';
  DateTime _lastSentTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Prevent duplicate submission if already waiting for AI response
    if (state.isLoading) {
      debugPrint('[ChatController] Ignoring message: already loading a response.');
      return;
    }

    // 2. Prevent identical duplicate message within 2 seconds
    final now = DateTime.now();
    if (trimmed == _lastSentText && now.difference(_lastSentTime).inMilliseconds < 2000) {
      debugPrint('[ChatController] Ignoring duplicate send of: "$trimmed"');
      return;
    }

    _lastSentText = trimmed;
    _lastSentTime = now;

    final userMsg = ChatMessageItem(text: trimmed, isUser: true);
    final updatedMessages = [...state.messages, userMsg];

    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      errorMessage: null,
    );

    final history = updatedMessages.map((m) {
      return {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      };
    }).toList();

    try {
      final TutorAiResponse aiResponse = await aiService.getTutorResponse(
        userMessage: text.trim(),
        cefrLevel: state.cefrLevel,
        scenarioTitle: state.scenarioTitle,
        conversationHistory: history,
      );

      final aiMsg = ChatMessageItem(
        text: aiResponse.conversationalResponse,
        isUser: false,
        correction: aiResponse.grammarCorrection,
      );

      state = state.copyWith(
        messages: [...updatedMessages, aiMsg],
        isLoading: false,
        fluencyScore: aiResponse.fluencyScore,
      );

      // Speak response automatically
      speakText(aiResponse.conversationalResponse);
    } catch (e, stack) {
      debugPrint('[ChatController] Error in sendMessage: $e\n$stack');
      final fallbackMsg = ChatMessageItem(
        text: "I received your message: \"$text\". How would you like to continue our conversation?",
        isUser: false,
      );
      state = state.copyWith(
        messages: [...updatedMessages, fallbackMsg],
        isLoading: false,
        errorMessage: "Error: ${e.toString()}",
      );
    }
  }

  Future<void> speakText(String text) async {
    try {
      await stopTts();

      // 1. Attempt natural conversational voice synthesis via Google Cloud Journey Neural TTS
      final audioBytes = await _googleTtsService.synthesizeSpeech(text: text);
      if (audioBytes != null && audioBytes.isNotEmpty) {
        debugPrint('[ChatController] Playing Google Journey neural voice audio (${audioBytes.length} bytes)');
        state = state.copyWith(isPlayingTts: true);
        await _audioPlayer.play(BytesSource(audioBytes));
        return;
      }

      // 2. Seamless Fallback: Use local device computer sound (flutter_tts)
      debugPrint('[ChatController] Google Journey neural voice unavailable or quota reached. Falling back to local device TTS.');
      await _speakWithLocalTts(text);
    } catch (e) {
      debugPrint('[ChatController] Error during neural voice playback: $e. Falling back to local TTS.');
      await _speakWithLocalTts(text);
    }
  }

  Future<void> _speakWithLocalTts(String text) async {
    try {
      await _ensureNaturalVoiceSelected();
      state = state.copyWith(isPlayingTts: true);
      final result = await _tts.speak(text);
      if (result != 1) {
        state = state.copyWith(isPlayingTts: false);
      }
      // Natural speech rate estimate: ~2.3 words per second
      final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      final estimatedSeconds = (wordCount / 2.3).ceil().clamp(3, 60);
      Future.delayed(Duration(seconds: estimatedSeconds), () {
        if (mounted && state.isPlayingTts) {
          state = state.copyWith(isPlayingTts: false);
        }
      });
    } catch (_) {
      state = state.copyWith(isPlayingTts: false);
    }
  }

  Future<void> stopTts() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    state = state.copyWith(isPlayingTts: false);
  }

  Timer? _initialSilenceTimer;
  Timer? _speechDoneDebounceTimer;
  Timer? _rearmTimer;
  bool _hasReceivedSpeech = false;
  int _audioCaptureRetries = 0;
  String _currentSessionWords = '';
  void Function(String words, bool isFinal)? _activeOnResult;
  void Function()? _activeOnDone;

  /// Starts speech-to-text recording with callbacks for streaming transcription
  Future<bool> startListening({
    required void Function(String words, bool isFinal) onResult,
    void Function()? onDone,
  }) async {
    try {
      await stopTts();
      _cancelSpeechTimers();

      // Ensure any previous speech session is cleanly cancelled to avoid hardware lock
      try {
        if (_speech.isListening) {
          await _speech.stop();
        }
        await _speech.cancel();
      } catch (_) {}

      if (kIsWeb) {
        // Brief pause to allow the browser's audio subsystem to release the hardware handle
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _hasReceivedSpeech = false;
      _audioCaptureRetries = 0;
      _currentSessionWords = '';
      _activeOnResult = onResult;
      _activeOnDone = onDone;

      if (!kIsWeb) {
        final status = await Permission.microphone.status;
        if (!status.isGranted) {
          final result = await Permission.microphone.request();
          if (!result.isGranted) {
            state = state.copyWith(
              isRecording: false,
              errorMessage: 'Microphone permission denied. Please enable microphone permission in device Settings.',
            );
            return false;
          }
        }
      }

      // Ensure active listeners are bound directly
      _speech.errorListener = _onSpeechError;
      _speech.statusListener = _onSpeechStatus;

      if (!_speechInitialized) {
        _speechInitialized = await _speech.initialize(
          onError: _onSpeechError,
          onStatus: _onSpeechStatus,
        );
      }

      if (!_speechInitialized) {
        state = state.copyWith(
          isRecording: false,
          errorMessage: 'Speech recognition is not available or permission was denied.',
        );
        return false;
      }

      state = state.copyWith(isRecording: true, errorMessage: null);

      // Initial grace period: Wait at least 6 seconds for the user to start talking!
      _initialSilenceTimer = Timer(const Duration(seconds: 6), () {
        if (!_hasReceivedSpeech && state.isRecording) {
          debugPrint('[ChatController] Initial 6 seconds silence reached without speech.');
          stopListening();
        }
      });

      await _startInternalListen();
      return true;
    } catch (e, stack) {
      debugPrint('[ChatController] Error starting speech recognition: $e\n$stack');
      _cancelSpeechTimers();
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Microphone/Speech error: ${e.toString()}',
      );
      return false;
    }
  }

  void _onSpeechError(SpeechRecognitionError errorNotification) {
    final msg = errorNotification.errorMsg.toLowerCase();
    debugPrint('[ChatController] STT error: $msg (permanent: ${errorNotification.permanent})');

    final isPermissionError = msg.contains('not-allowed') ||
        msg.contains('permission') ||
        msg.contains('service-not-allowed') ||
        msg.contains('not supported');

    if (isPermissionError) {
      _cancelSpeechTimers();
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Microphone permission denied. Please grant microphone access in browser or device settings.',
      );
      return;
    }

    final isSilenceError = msg == 'no-speech' ||
        msg == 'error_no_speech' ||
        msg == 'error_no_match' ||
        msg == 'error_speech_timeout' ||
        msg == 'aborted';

    if (isSilenceError) {
      if (!_hasReceivedSpeech && state.isRecording) {
        debugPrint('[ChatController] Silence detected ($msg). Engine will close and onStatus will cleanly re-arm.');
      } else if (_hasReceivedSpeech && state.isRecording) {
        debugPrint('[ChatController] Silence detected after speech. Finalizing session.');
        _finalizeSpeechSession();
      }
      return;
    }

    if (msg.contains('audio-capture')) {
      try {
        _speech.cancel();
      } catch (_) {}

      if (!_hasReceivedSpeech && state.isRecording && _audioCaptureRetries < 2) {
        _audioCaptureRetries++;
        debugPrint('[ChatController] audio-capture warning (retry $_audioCaptureRetries/2). Waiting 800ms for hardware release...');
        _rearmTimer?.cancel();
        _rearmTimer = Timer(const Duration(milliseconds: 800), () async {
          if (state.isRecording && !_hasReceivedSpeech) {
            await _startInternalListen();
          }
        });
        return;
      }
      _cancelSpeechTimers();
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Microphone is busy or unavailable. Please check that your microphone is plugged in, active in Windows, and not in exclusive use by another app.',
      );
      return;
    }

    // Other unexpected errors
    _cancelSpeechTimers();
    try {
      _speech.cancel();
    } catch (_) {}
    state = state.copyWith(
      isRecording: false,
      errorMessage: msg.isNotEmpty ? 'Speech error: $msg' : null,
    );
  }

  void _onSpeechStatus(String status) {
    debugPrint('[ChatController] STT status: $status (isRecording: ${state.isRecording}, hasReceivedSpeech: $_hasReceivedSpeech)');
    if (status == 'notListening' || status == 'done') {
      if (_hasReceivedSpeech) {
        _finalizeSpeechSession();
      } else if (state.isRecording) {
        // Platform engine closed on initial silence; cleanly re-arm after driver release buffer!
        _keepListeningAlive();
      }
    }
  }

  Future<void> _startInternalListen() async {
    if (!state.isRecording) return;
    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            _hasReceivedSpeech = true;
            _currentSessionWords = words;
            _initialSilenceTimer?.cancel();
            _rearmTimer?.cancel();

            // Stream transcribed words to UI in real-time
            _activeOnResult?.call(words, false);

            // Reset debounce timer: wait 2.5s of silence AFTER user stops speaking before auto-sending
            _speechDoneDebounceTimer?.cancel();
            _speechDoneDebounceTimer = Timer(const Duration(milliseconds: 2500), () {
              debugPrint('[ChatController] 2.5s silence detected after user finished speaking. Completing.');
              _finalizeSpeechSession();
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          pauseFor: const Duration(seconds: 10),
          listenFor: const Duration(seconds: 60),
          localeId: 'en-US',
        ),
      );
    } catch (e) {
      debugPrint('[ChatController] _startInternalListen error: $e');
    }
  }

  void _keepListeningAlive() {
    if (!state.isRecording || _hasReceivedSpeech) return;
    _rearmTimer?.cancel();
    _rearmTimer = Timer(const Duration(milliseconds: 650), () async {
      if (!state.isRecording || _hasReceivedSpeech) return;
      if (_speech.isListening) {
        debugPrint('[ChatController] Speech engine is already active.');
        return;
      }
      debugPrint('[ChatController] Re-arming speech listener to keep initial 6s window alive...');
      await _startInternalListen();
    });
  }

  void _finalizeSpeechSession() {
    if (!state.isRecording && _currentSessionWords.isEmpty) return;
    _cancelSpeechTimers();
    state = state.copyWith(isRecording: false);

    final wordsToSend = _currentSessionWords.trim();
    _currentSessionWords = '';
    _hasReceivedSpeech = false;
    _activeOnResult = null; // Unhook result stream so late engine events cannot repopulate text field
    final onDoneCallback = _activeOnDone;
    _activeOnDone = null; // Guaranteed single execution

    try {
      _speech.stop();
    } catch (_) {}

    if (wordsToSend.isNotEmpty) {
      onDoneCallback?.call();
    }
  }

  void _cancelSpeechTimers() {
    _initialSilenceTimer?.cancel();
    _initialSilenceTimer = null;
    _speechDoneDebounceTimer?.cancel();
    _speechDoneDebounceTimer = null;
    _rearmTimer?.cancel();
    _rearmTimer = null;
  }

  /// Stops speech-to-text recording manually
  Future<void> stopListening() async {
    _cancelSpeechTimers();
    state = state.copyWith(isRecording: false);
    _hasReceivedSpeech = false;
    _activeOnResult = null;
    _activeOnDone = null;
    try {
      await _speech.stop();
      await _speech.cancel();
    } catch (_) {}
  }

  void setCefrLevel(String level) {
    state = state.copyWith(cefrLevel: level);
  }

  void toggleRecording() {
    state = state.copyWith(isRecording: !state.isRecording);
  }

  @override
  void dispose() {
    _cancelSpeechTimers();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
