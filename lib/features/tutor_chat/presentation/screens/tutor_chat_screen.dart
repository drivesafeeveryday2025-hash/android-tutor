import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/soundwave_visualizer.dart';

class TutorChatScreen extends ConsumerStatefulWidget {
  const TutorChatScreen({super.key});

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      ref.read(chatControllerProvider.notifier).sendMessage(text);
      _scrollToBottom();
    }
  }

  Future<void> _handleMicTap() async {
    final chatNotifier = ref.read(chatControllerProvider.notifier);
    final isRecording = ref.read(chatControllerProvider).isRecording;

    if (isRecording) {
      await chatNotifier.stopListening();
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        _handleSend();
      }
    } else {
      _textController.clear();
      final started = await chatNotifier.startListening(
        onResult: (words, isFinal) {
          if (mounted) {
            setState(() {
              _textController.text = words;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          }
        },
        onDone: () {
          if (mounted) {
            final text = _textController.text.trim();
            if (text.isNotEmpty) {
              _handleSend();
            }
          }
        },
      );

      if (!started && mounted) {
        final error = ref.read(chatControllerProvider).errorMessage ??
            'Microphone access unavailable. Please grant microphone permission in your browser or device settings.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.roseError,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  void _showApiKeyDialog(BuildContext context) {
    final keyController = TextEditingController(text: EnvConfig.openAiApiKey);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('OpenAI API Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your OpenAI API key below for live GPT-4o-mini responses, or leave empty to use the built-in Smart Offline Tutor.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'sk-proj-...',
                labelText: 'OpenAI API Key',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              EnvConfig.openAiApiKey = keyController.text.trim();
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(EnvConfig.openAiApiKey.isNotEmpty
                      ? 'API Key saved successfully!'
                      : 'Switched to Smart Offline Tutor mode.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);

    ref.listen<ChatState>(chatControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.roseError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(chatControllerProvider.notifier).stopTts();
          ref.read(chatControllerProvider.notifier).stopListening();
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryIndigo,
              child: Text(
                EnvConfig.tutorName.isNotEmpty ? EnvConfig.tutorName[0] : 'C',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${EnvConfig.tutorName} (AI Tutor)', style: const TextStyle(fontSize: 16)),
                Text(
                  'Fluency: ${state.fluencyScore}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.emeraldSuccess),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded, size: 20, color: AppColors.amberWarning),
            tooltip: 'Configure OpenAI API Key',
            onPressed: () => _showApiKeyDialog(context),
          ),
          PopupMenuButton<String>(
            initialValue: state.cefrLevel,
            tooltip: 'Select CEFR Level',
            icon: Chip(
              label: Text(state.cefrLevel),
              backgroundColor: AppColors.primaryIndigo.withValues(alpha: 0.2),
              side: BorderSide.none,
            ),
            onSelected: (level) {
              ref.read(chatControllerProvider.notifier).setCefrLevel(level);
            },
            itemBuilder: (context) => ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                .map((level) => PopupMenuItem(value: level, child: Text('CEFR $level')))
                .toList(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Soundwave Visualizer Bar (fixed height to prevent layout shift)
            Container(
              height: 48,
              alignment: Alignment.center,
              color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.4),
              child: SoundwaveVisualizer(
                isRecording: state.isRecording,
                isPlayingTts: state.isPlayingTts,
              ),
            ),

            // Chat Messages Stream List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final msg = state.messages[index];
                  return ChatBubble(
                    text: msg.text,
                    isUser: msg.isUser,
                    correction: msg.correction,
                    onPlayTts: () {
                      ref.read(chatControllerProvider.notifier).speakText(msg.text);
                    },
                  );
                },
              ),
            ),

            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SpinKitThreeBounce(
                  color: AppColors.primaryIndigo,
                  size: 24,
                ),
              ),

            // Input Toolbar Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Mic / Voice Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: _handleMicTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: state.isRecording
                              ? AppColors.roseError
                              : AppColors.primaryIndigo,
                          shape: BoxShape.circle,
                          boxShadow: state.isRecording
                              ? [
                                  BoxShadow(
                                    color: AppColors.roseError.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          state.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Expandable Text Input (Supports long sentences & paragraphs)
                  Expanded(
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          _handleSend();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                        decoration: InputDecoration(
                          hintText: state.isRecording
                              ? 'Listening... Speak in English now'
                              : 'Type a message or tap mic to speak...',
                          hintStyle: TextStyle(
                            color: state.isRecording
                                ? AppColors.roseError
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: state.isRecording ? FontWeight.w600 : FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Send Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.primaryIndigo),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
