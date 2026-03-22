import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/providers.dart';
import '../theme.dart';

class PerformanceAnalyticsScreen extends ConsumerWidget {
  final bool embeddedInShell;

  const PerformanceAnalyticsScreen({super.key, this.embeddedInShell = false});

  static String _fmtHours(int minutes) {
    final h = minutes ~/ 60;
    if (h <= 0) return '${minutes}m';
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(analyticsSummaryProvider);

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
                children: [
                  if (!embeddedInShell &&
                      (ModalRoute.of(context)?.canPop ?? false)) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 16, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Text(
                    'Analytics',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              async.when(
                data: (summary) {
                  final week = summary?['week'] as Map<String, dynamic>?;
                  final month = summary?['month'] as Map<String, dynamic>?;
                  final streak = summary?['streak'] as Map<String, dynamic>?;
                  final totalMinMonth = month?['total_minutes'] as int? ?? 42 * 60;
                  final avgMood = week?['avg_mood'] as num?;
                  final sessions = week?['session_count'] as int? ?? 68;
                  final best = streak?['longest'] as int? ?? 12;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Total Hours',
                              value: _fmtHours(totalMinMonth),
                              sub: 'This month',
                              color: AppColors.primaryContainer,
                              textColor: AppColors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Avg. Mood',
                              value: avgMood != null ? '😊 ${avgMood.toStringAsFixed(1)}' : '😊 4.2',
                              sub: 'This week',
                              color: AppColors.secondaryContainer,
                              textColor: AppColors.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Best Streak',
                              value: '$best days',
                              sub: 'Personal best',
                              color: AppColors.tertiaryContainer,
                              textColor: AppColors.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Sessions',
                              value: '$sessions',
                              sub: 'Completed (week)',
                              color: AppColors.surfaceContainerHighest,
                              textColor: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              Text(
                'Study Hours This Week',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Bar(label: 'M', hours: 2.5, max: 6),
                    _Bar(label: 'T', hours: 4.0, max: 6),
                    _Bar(label: 'W', hours: 5.5, max: 6),
                    _Bar(label: 'T', hours: 3.0, max: 6),
                    _Bar(label: 'F', hours: 4.8, max: 6),
                    _Bar(label: 'S', hours: 1.5, max: 6),
                    _Bar(label: 'S', hours: 0.0, max: 6),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Mood vs. Performance',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _MoodRow(mood: '🤩 Amazing', percent: 0.9, sessions: 12),
                    const SizedBox(height: 12),
                    _MoodRow(mood: '😊 Great', percent: 0.75, sessions: 28),
                    const SizedBox(height: 12),
                    _MoodRow(mood: '🙂 Good', percent: 0.55, sessions: 18),
                    const SizedBox(height: 12),
                    _MoodRow(mood: '😐 Okay', percent: 0.35, sessions: 8),
                    const SizedBox(height: 12),
                    _MoodRow(mood: '😔 Low', percent: 0.2, sessions: 2),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Subject Breakdown',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _SubjectRow(subject: 'Mathematics', hours: 18, color: AppColors.primary),
              const SizedBox(height: 8),
              _SubjectRow(subject: 'Physics', hours: 12, color: AppColors.secondary),
              const SizedBox(height: 8),
              _SubjectRow(subject: 'Literature', hours: 8, color: AppColors.tertiary),
              const SizedBox(height: 8),
              _SubjectRow(subject: 'Chemistry', hours: 4, color: AppColors.outlineVariant),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value, sub;
  final Color color, textColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.tertiary),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double hours, max;

  const _Bar({required this.label, required this.hours, required this.max});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          hours > 0 ? '${hours.toStringAsFixed(0)}h' : '',
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: (hours / max) * 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _MoodRow extends StatelessWidget {
  final String mood;
  final double percent;
  final int sessions;

  const _MoodRow({required this.mood, required this.percent, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(mood, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$sessions',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.tertiary),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final String subject;
  final double hours;
  final Color color;

  const _SubjectRow({required this.subject, required this.hours, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subject,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
            ),
          ),
          Text(
            '${hours.toStringAsFixed(0)}h',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
