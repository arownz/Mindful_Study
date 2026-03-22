import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap.dart';
import '../providers/providers.dart';
import '../services/dio_client.dart';
import '../theme.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  final bool embeddedInShell;

  const FocusTimerScreen({super.key, this.embeddedInShell = false});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  static const _totalSeconds = 25 * 60;
  int _remaining = _totalSeconds;
  bool _running = false;
  bool _reportedComplete = false;
  Timer? _timer;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breatheAnim = Tween(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breatheController.dispose();
    super.dispose();
  }

  Future<void> _completeSession() async {
    if (!supabaseEnabled) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    try {
      await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/sessions/complete',
        data: {
          'duration_seconds': _totalSeconds,
          'subject': 'Focus session',
        },
      );
      ref.invalidate(analyticsSummaryProvider);
    } on DioException {
      // offline / API down — ignore for MVP
    }
  }

  void _onTimerFinished() {
    if (_reportedComplete) return;
    _reportedComplete = true;
    unawaited(_completeSession());
  }

  void _toggle() {
    setState(() => _running = !_running);
    if (_running) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining > 0) {
          setState(() => _remaining--);
        } else {
          _timer?.cancel();
          setState(() => _running = false);
          _onTimerFinished();
        }
      });
    } else {
      _timer?.cancel();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _totalSeconds;
      _running = false;
      _reportedComplete = false;
    });
  }

  String get _timeLabel {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_remaining / _totalSeconds);

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(studyPlanProvider);
    final blocks = (plan?['blocks'] as List<dynamic>?) ?? const [];
    var subjectLine = 'Mathematics — Calculus';
    if (blocks.isNotEmpty) {
      final b = blocks.first as Map<String, dynamic>;
      final s = b['subject']?.toString() ?? 'Subject';
      final t = b['topic']?.toString() ?? '';
      subjectLine = t.isEmpty ? s : '$s — $t';
    }

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
                  if (!widget.embeddedInShell &&
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
                    'Focus Timer',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.book_outlined,
                        size: 16, color: AppColors.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        subjectLine,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: ScaleTransition(
                  scale: _breatheAnim,
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 6,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timeLabel,
                              style: GoogleFonts.manrope(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              _running ? 'Focus' : 'Paused',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleButton(
                    icon: Icons.refresh,
                    onTap: _reset,
                    bg: AppColors.surfaceContainerLow,
                    iconColor: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _running ? Icons.pause : Icons.play_arrow,
                        color: AppColors.onPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _CircleButton(
                    icon: Icons.skip_next,
                    onTap: () => context.go('/analytics'),
                    bg: AppColors.surfaceContainerLow,
                    iconColor: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Sessions', value: '3'),
                    _Divider(),
                    _StatItem(label: 'Focus Time', value: '1h 15m'),
                    _Divider(),
                    _StatItem(label: 'Streak', value: '5 days'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg, iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.surfaceContainerHighest);
  }
}
