import 'package:flutter/material.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/grammar_correction.dart';
import 'grammar_correction_card.dart';

/// Renders a message bubble for User or AI with optional TTS play action and grammar correction callout.
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final GrammarCorrection? correction;
  final VoidCallback? onPlayTts;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.correction,
    this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = isUser
        ? AppColors.primaryIndigo
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    final textColor = isUser
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryIndigo,
                  child: Text(
                    EnvConfig.tutorName.isNotEmpty ? EnvConfig.tutorName[0] : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      if (!isUser && onPlayTts != null) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: onPlayTts,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.volume_up_rounded,
                                size: 16,
                                color: AppColors.primaryIndigoLight,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Listen',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryIndigoLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.emeraldSuccess,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ],
            ],
          ),
          if (correction != null && correction!.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40),
              child: GrammarCorrectionCard(correction: correction!),
            ),
        ],
      ),
    );
  }
}
