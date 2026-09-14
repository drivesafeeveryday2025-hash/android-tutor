import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/grammar_correction.dart';

/// Card widget presenting real-time grammar feedback with original text, corrected text, and explanation.
class GrammarCorrectionCard extends StatelessWidget {
  final GrammarCorrection correction;

  const GrammarCorrectionCard({
    super.key,
    required this.correction,
  });

  @override
  Widget build(BuildContext context) {
    if (!correction.hasError) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amberWarning.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.amberWarning,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Grammar Tip (${correction.errorCategory})',
                style: const TextStyle(
                  color: AppColors.amberWarning,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Original: ',
                  style: TextStyle(
                    color: AppColors.roseError,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: correction.originalSentence,
                  style: const TextStyle(
                    color: AppColors.roseError,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Better: ',
                  style: TextStyle(
                    color: AppColors.emeraldSuccess,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: correction.correctedSentence,
                  style: const TextStyle(
                    color: AppColors.emeraldSuccess,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (correction.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              correction.explanation,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
