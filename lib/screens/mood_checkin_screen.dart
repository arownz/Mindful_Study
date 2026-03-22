import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap.dart';
import '../providers/providers.dart';
import '../services/dio_client.dart';
import '../services/local_plan.dart';
import '../theme.dart';
import '../widgets/gradient_primary_button.dart';

class MoodCheckInScreen extends ConsumerStatefulWidget {
  const MoodCheckInScreen({super.key});

  @override
  ConsumerState<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends ConsumerState<MoodCheckInScreen> {
  int? _selectedMood;
  double _energyLevel = 3;
  final List<String> _selectedFactors = [];
  bool _submitting = false;

  final _moods = [
    ('😔', 'Low'),
    ('😐', 'Okay'),
    ('🙂', 'Good'),
    ('😊', 'Great'),
    ('🤩', 'Amazing'),
  ];

  final _factors = [
    'Slept well', 'Exercised', 'Stressed',
    'Motivated', 'Distracted', 'Focused',
  ];

  Future<void> _continue() async {
    if (_selectedMood == null || _submitting) return;
    setState(() => _submitting = true);
    final moodIndex = _selectedMood!;
    final energy = _energyLevel.round().clamp(1, 5);
    final factors = List<String>.from(_selectedFactors);

    try {
      Map<String, dynamic>? plan;

      if (supabaseEnabled && Supabase.instance.client.auth.currentSession != null) {
        final uid = Supabase.instance.client.auth.currentUser!.id;
        await Supabase.instance.client.from('mood_logs').insert({
          'user_id': uid,
          'mood_index': moodIndex,
          'energy_level': energy,
          'factors': factors,
        });

        try {
          final dio = ref.read(dioProvider);
          final res = await dio.post<Map<String, dynamic>>(
            '/plans/generate',
            data: {
              'mood_index': moodIndex,
              'energy_level': energy,
              'subjects': <String>['Mathematics', 'Physics', 'Literature'],
            },
          );
          plan = res.data;
        } on DioException {
          plan = buildLocalPlan(
            moodIndex: moodIndex,
            energyLevel: energy,
            subjects: const ['Mathematics', 'Physics', 'Literature'],
          );
        }
      } else {
        plan = buildLocalPlan(
          moodIndex: moodIndex,
          energyLevel: energy,
          subjects: const ['Mathematics', 'Physics', 'Literature'],
        );
      }

      ref.read(studyPlanProvider.notifier).state = plan;
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save check-in: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text(
                'How are you\nfeeling today?',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.64,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'I Study Buddy adapts your plan to how you feel',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.tertiary),
              ),
              const SizedBox(height: 40),
              _label('Current Mood'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_moods.length, (i) {
                  final selected = _selectedMood == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 72,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: selected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_moods[i].$1, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            _moods[i].$2,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              _label('Energy Level'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('🪫', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.surfaceContainerHighest,
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.1),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _energyLevel,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (v) => setState(() => _energyLevel = v),
                      ),
                    ),
                  ),
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 32),
              _label("What's influencing you?"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _factors.map((f) {
                  final selected = _selectedFactors.contains(f);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected ? _selectedFactors.remove(f) : _selectedFactors.add(f);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.secondaryContainer : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                        border: selected ? Border.all(color: AppColors.secondary, width: 1) : null,
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: selected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              GradientPrimaryButton(
                label: _submitting ? 'Saving…' : 'Start Study Session',
                onPressed: _selectedMood == null || _submitting ? null : _continue,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      );
}
