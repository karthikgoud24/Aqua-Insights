
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  int score = 0;
  int best = 0;
  int timeLeft = 20;
  Timer? timer;

  final qs = const [
    ('What does boiling do to water?', ['Kills most microbes', 'Removes heavy metals', 'Adds minerals'], 0),
    ('Best way to store water?', ['Open bucket', 'Covered, clean container', 'Glass in sun'], 1),
    ('Which indicates iron/rust?', ['Greenish tint', 'Reddish-brown tint', 'Blue tint'], 1),
    ('What removes odors/taste?', ['UV light', 'Activated carbon', 'Boiling only'], 1),
    ('Turbid water should be…', ['Filtered then treated', 'Ignored', 'Only chlorinated'], 0),
    ('Which is NOT photo-detectable?', ['Oil sheen', 'Algae tint', 'Radioactivity'], 2),
    ('Safe bleach dosing per liter?', ['2 drops (5–6%)', '10 drops', 'No bleach'], 0),
    ('Kids should wash hands for…', ['5 sec', '10 sec', '20 sec'], 2),
    ('Which saves water?', ['Running tap while brushing', 'Using a bucket for rinse', 'Daily car wash with hose'], 1),
    ('Standing water risk?', ['Mosquito breeding', 'No risk', 'Adds oxygen'], 0),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timeLeft = 20;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft == 0) {
        _next();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => best = prefs.getInt('best_score') ?? 0);
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', best);
  }

  void _answer(int i) {
    final correct = qs[index].$3;
    if (i == correct) score++;
    _next();
  }

  void _next() async {
    if (index < qs.length - 1) {
      setState(() {
        index++;
      });
      _startTimer();
    } else {
      timer?.cancel();
      if (score > best) { best = score; await _saveBest(); }
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Quiz finished!'),
          content: Text('Score: $score / ${qs.length}\nBest: $best'),
          actions: [
            TextButton(onPressed: () { Navigator.pop(c); setState(() { index = 0; score = 0; }); _startTimer();}, child: const Text('Retry')),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = qs[index];
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz & Badges')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text('Q ${index+1}/${qs.length}')),
                const SizedBox(width: 12),
                Chip(label: Text('Time $timeLeft s')),
                const Spacer(),
                Chip(label: Text('Best $best')),
              ],
            ),
            const SizedBox(height: 12),
            Text(q.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (var i = 0; i < q.$2.length; i++)
              Card(
                child: ListTile(
                  title: Text(q.$2[i]),
                  onTap: () => _answer(i),
                ),
              ),
            const Spacer(),
            LinearProgressIndicator(value: (index+1)/qs.length),
          ],
        ),
      ),
    );
  }
}
