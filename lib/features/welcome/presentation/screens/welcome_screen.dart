import 'package:flutter/material.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tutor_chat/presentation/screens/tutor_chat_screen.dart';

/// The welcoming landing frontpage displayed when users open the application.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Badge / Top Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryIndigo.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: AppColors.primaryIndigoLight,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'AI-Powered Interactive Language Tutor',
                          style: TextStyle(
                            color: AppColors.primaryIndigoLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chole Avatar Hero Section with Glowing Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryIndigo,
                              AppColors.primaryIndigoLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryIndigo.withValues(alpha: 0.35),
                              blurRadius: 18,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: AppColors.darkBackground,
                            child: CircleAvatar(
                              radius: 34,
                              backgroundColor: AppColors.primaryIndigo,
                              child: Text(
                                EnvConfig.tutorName.isNotEmpty ? EnvConfig.tutorName[0] : 'C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Headline & Subtitle
                  const Text(
                    'Speak English with Confidence',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Meet ${EnvConfig.tutorName}, your patient AI English tutor. Practice spoken conversations, get instant grammar tips, and improve fluency at your own pace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Feature Cards
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.record_voice_over_rounded,
                    title: 'Real-Time Voice Practice',
                    description:
                        'Speak naturally and hear ${EnvConfig.tutorName}’s friendly voice replies in real time.',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.auto_fix_high_rounded,
                    title: 'Instant Grammar Feedback',
                    description:
                        'Get gentle grammar corrections and upgraded vocabulary recommendations.',
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.trending_up_rounded,
                    title: 'Adaptive CEFR Levels',
                    description:
                        'Tailored dialogue from A1 to C2 with dynamic fluency scoring.',
                  ),
                  const SizedBox(height: 18),

                  // Quick Topic Starters
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ready to explore topics like:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTopicChip(context, '☕ Ordering at a Café'),
                      _buildTopicChip(context, '✈️ Travel & Directions'),
                      _buildTopicChip(context, '💼 Job Interview Prep'),
                      _buildTopicChip(context, '🌟 Casual Daily Chat'),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Primary Call To Action (CTA) Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TutorChatScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryIndigo,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primaryIndigo.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 19),
                          SizedBox(width: 8),
                          Text(
                            'Try Out English Tutor',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 19),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footnote
                  Text(
                    'Free tier AI ready • Zero configuration required',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                          : AppColors.lightTextSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
              : AppColors.lightSurfaceVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryIndigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryIndigo, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurfaceVariant.withValues(alpha: 0.4)
              : AppColors.lightSurfaceVariant,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}

