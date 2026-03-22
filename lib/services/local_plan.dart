/// Rule-based plan when API is unavailable (mirrors backend fallback).
Map<String, dynamic> buildLocalPlan({
  required int moodIndex,
  required int energyLevel,
  List<String>? subjects,
}) {
  final subs = subjects ?? ['Mathematics', 'Physics', 'Literature'];
  final minutes = energyLevel >= 3 ? 25 : 15;
  final blocks = <Map<String, dynamic>>[];
  for (var i = 0; i < subs.length && i < 3; i++) {
    blocks.add({
      'subject': subs[i],
      'topic': 'Adaptive focus block',
      'minutes': minutes + i * 5,
      'is_current': i == 0,
    });
  }
  return {
    'mood_index': moodIndex,
    'energy_level': energyLevel,
    'blocks': blocks,
    'motivation': 'Small steps keep momentum. You\'ve got this.',
  };
}
