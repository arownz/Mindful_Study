import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';
import '../theme.dart';
import '../widgets/gradient_primary_button.dart';

class StudyDashboardScreen extends ConsumerWidget {
  const StudyDashboardScreen({super.key});

  static String _greetingForHour(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _moodLine(Map<String, dynamic>? plan) {
    if (plan == null) return 'High energy · Focused';
    final mi = plan['mood_index'];
    final energy = plan['energy_level'];
    if (mi is! int) return 'High energy · Focused';
    const labels = ['Low', 'Okay', 'Good', 'Great', 'Amazing'];
    final label = labels[mi.clamp(0, 4)];
    final e = energy is int ? energy : 3;
    return 'Mood $label · Energy $e/5';
  }

  static String _emojiForMood(Map<String, dynamic>? plan) {
    const emojis = ['😔', '😐', '🙂', '😊', '🤩'];
    final mi = plan?['mood_index'];
    if (mi is! int) return '😊';
    return emojis[mi.clamp(0, 4)];
  }

  static String _titleForMood(Map<String, dynamic>? plan) {
    const titles = ['Feeling Low', 'Feeling Okay', 'Feeling Good', 'Feeling Great', 'Feeling Amazing'];
    final mi = plan?['mood_index'];
    if (mi is! int) return 'Feeling Great';
    return titles[mi.clamp(0, 4)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final plan = ref.watch(studyPlanProvider);
    final blocks = (plan?['blocks'] as List<dynamic>?) ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, Alex',
                        style: GoogleFonts.manrope(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          letterSpacing: -0.52,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Text(_emojiForMood(plan), style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleForMood(plan),
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSecondaryContainer,
                            ),
                          ),
                          Text(
                            _moodLine(plan),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Today\'s Plan',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              if (blocks.isEmpty) ...[
                _SubjectCard(
                  subject: 'Mathematics',
                  topic: 'Calculus — Integration',
                  duration: '45 min',
                  color: AppColors.primaryContainer,
                  textColor: AppColors.onPrimaryContainer,
                  isCurrent: true,
                ),
                const SizedBox(height: 8),
                _SubjectCard(
                  subject: 'Physics',
                  topic: 'Thermodynamics',
                  duration: '30 min',
                  color: AppColors.surfaceContainerLow,
                  textColor: AppColors.onSurface,
                ),
                const SizedBox(height: 8),
                _SubjectCard(
                  subject: 'Literature',
                  topic: 'Essay Review',
                  duration: '20 min',
                  color: AppColors.surfaceContainerLow,
                  textColor: AppColors.onSurface,
                ),
              ] else
                ...List.generate(blocks.length, (i) {
                  final b = blocks[i] as Map<String, dynamic>;
                  final subject = b['subject']?.toString() ?? 'Subject';
                  final topic = b['topic']?.toString() ?? '';
                  final minutes = b['minutes'];
                  final dur = minutes is int ? '$minutes min' : '${minutes ?? 25} min';
                  final isCurrent = b['is_current'] == true;
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : 8),
                    child: _SubjectCard(
                      subject: subject,
                      topic: topic,
                      duration: dur,
                      color: isCurrent ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                      textColor: isCurrent ? AppColors.onPrimaryContainer : AppColors.onSurface,
                      isCurrent: isCurrent,
                    ),
                  );
                }),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Progress',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '12h 30m',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .asMap()
                    .entries
                    .map((e) => _DayBar(
                          label: e.value,
                          height: [0.4, 0.7, 0.9, 0.5, 0.8, 0.3, 0.0][e.key],
                          isToday: e.key == 0,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              GradientPrimaryButton(
                label: 'Start Focus Session',
                onPressed: () => context.go('/timer'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject, topic, duration;
  final Color color, textColor;
  final bool isCurrent;

  const _SubjectCard({
    required this.subject,
    required this.topic,
    required this.duration,
    required this.color,
    required this.textColor,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Now',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  topic,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            duration,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final String label;
  final double height;
  final bool isToday;

  const _DayBar({required this.label, required this.height, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 32,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 20,
              height: height * 60,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isToday ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
