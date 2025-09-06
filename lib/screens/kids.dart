
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KidsCornerScreen extends StatefulWidget {
  KidsCornerScreen({super.key});

  @override
  State<KidsCornerScreen> createState() => _KidsCornerScreenState();
}

class _KidsCornerScreenState extends State<KidsCornerScreen> with TickerProviderStateMixin {
  late final AnimationController _bubbleCtrl;
  late final Animation<double> _bubbleAnim;
  int stars = 0;
  int cleaned = 0;
  List<bool> trash = List.filled(16, true);
  List<String> facts = const [
    "Only 3% of Earth's water is fresh water.",
    "A running tap wastes ~6 liters per minute!",
    "Boiling kills most germs in water.",
    "Fish need clean water — keep rivers trash-free.",
    "Turn off the tap while brushing to save water.",
    "A single tree can move hundreds of liters of water via transpiration.",
    "Clouds are tiny water droplets floating in air!",
    "Ice is less dense than water — that’s why it floats.",
    "Water expands when it freezes, so pipes can burst in winter.",
    "Frogs need clean ponds to grow from tadpoles to frogs."
  ];

  // Storybook pages
  final List<String> story = const [
    "Hi! I’m Zippy the Water Drop. I travel from clouds to rivers and your home.",
    "I love clean bottles and covered tanks — dust can’t jump in!",
    "When water looks greenish, algae might be growing. Keep it shaded or flowing.",
    "Oil and soaps make shiny rainbow films. That’s bad for fish gills.",
    "We can make water safer: filter, boil, or use UV/chlorine carefully!",
    "Be a Water Hero: fix leaks, use a bucket for washing, and share clean-water tips."
  ];
  int storyIndex = 0;

  // Weekly checklist
  final List<_Task> tasks = [
    _Task("Turn off tap while brushing", false),
    _Task("Report a leak at home/school", false),
    _Task("Cover stored water", false),
    _Task("Pick 3 pieces of litter near water", false),
    _Task("Teach a friend one safety tip", false),
  ];

  // memory keys
  final _starsKey = 'kids_stars';
  final _tasksKey = 'kids_tasks';
  final _cleanedKey = 'kids_cleaned';

  @override
  void initState() {
    super.initState();
    _bubbleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _bubbleAnim = CurvedAnimation(parent: _bubbleCtrl, curve: Curves.easeInOut);
    _loadMemory();
  }

  Future<void> _loadMemory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      stars = prefs.getInt(_starsKey) ?? 0;
      cleaned = prefs.getInt(_cleanedKey) ?? 0;
      final t = prefs.getStringList(_tasksKey);
      if (t != null && t.length == tasks.length) {
        for (int i = 0; i < tasks.length; i++) tasks[i].done = t[i] == '1';
      }
    });
  }

  Future<void> _saveMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_starsKey, stars);
    await prefs.setInt(_cleanedKey, cleaned);
    await prefs.setStringList(_tasksKey, tasks.map((e) => e.done ? '1' : '0').toList());
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    super.dispose();
  }

  void _awardStars(int n) {
    stars += n;
    _saveMemory();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⭐ +$n star${n>1?'s':''}!')));
  }

  void _toggleTask(int i) {
    tasks[i].done = !tasks[i].done;
    final completed = tasks.where((t) => t.done).length;
    if (completed == tasks.length) {
      _awardStars(3);
      for (var t in tasks) t.done = false; // reset weekly
    } else {
      _awardStars(1);
    }
    _saveMemory();
    setState(() {});
  }

  void _cleanTrash(int i) {
    if (!trash[i]) return;
    trash[i] = false;
    cleaned++;
    if (cleaned % 5 == 0) _awardStars(1);
    _saveMemory();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kids Corner'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Chip(
              label: Text('Stars: $stars'),
              avatar: const Icon(Icons.star, color: Colors.amber),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Hero
          _HeroHeader(animation: _bubbleAnim),

          const SizedBox(height: 12),
          _sectionTitle(context, "Mini Comic"),
          _ComicPager(story: story, onPage: (i){ setState(() => storyIndex = i); }),

          const SizedBox(height: 16),
          _sectionTitle(context, "River Clean‑up Game"),
          _RiverGameGrid(trash: trash, onClean: _cleanTrash),
          const SizedBox(height: 8),
          Text('Cleaned: $cleaned pieces', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          _sectionTitle(context, "Fun Facts"),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: facts.map((f) => _factPill(f, cs)).toList(),
          ),

          const SizedBox(height: 16),
          _sectionTitle(context, "Weekly Water‑Hero Checklist"),
          for (int i = 0; i < tasks.length; i++)
            Card(
              child: CheckboxListTile(
                value: tasks[i].done,
                onChanged: (_) => _toggleTask(i),
                title: Text(tasks[i].title),
                secondary: const Icon(Icons.check_circle_outline),
              ),
            ),
          const SizedBox(height: 16),

          _sectionTitle(context, "Build‑a‑Filter (Steps)"),
          _FilterSteps(onComplete: () => _awardStars(2)),
          const SizedBox(height: 16),

          _sectionTitle(context, "Try a Tongue‑Twister"),
          Card(
            child: ListTile(
              title: const Text('“Fresh fish splash in fresh, clean streams.” Try saying it 5 times!'),
              trailing: FilledButton(onPressed: () => _awardStars(1), child: const Text('I did it')),
            ),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Kids Videos - Learn with Aqua', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (ctx, idx) {
                final path = 'assets/kids_videos/kid_video_${idx+1}.gif';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal:8.0),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(context: context, builder: (_) => Dialog(
                        child: Container(
                          color: Colors.black,
                          child: Image.asset(path, fit: BoxFit.contain),
                        ),
                      ));
                    },
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(path, width: 280, height: 150, fit: BoxFit.cover),
                        ),
                        const SizedBox(height:6),
                        Text('Aqua Adventure ${idx+1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Comics & Tips', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal:8.0),
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                  child: Column(children: [
                    Expanded(child: Image.asset('assets/images/boiling.png', fit: BoxFit.cover)),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('Tip ${i+1}: Save water', style: TextStyle(fontWeight: FontWeight.w600)))
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(s, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    );
  }

  Widget _factPill(String text, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.water_drop_outlined, size: 16),
        const SizedBox(width: 6),
        Text(text),
      ]),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Animation<double> animation;
  const _HeroHeader({required this.animation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) => CustomPaint(painter: _BubblesPainter(progress: animation.value)),
          )),
          const Positioned(left: 16, top: 14, child: Text('Zippy says:', style: TextStyle(fontWeight: FontWeight.w700))),
          const Positioned(left: 16, bottom: 20, child: Text('Be a Water Hero today!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const Positioned(right: 16, bottom: 18, child: Icon(Icons.child_care, size: 36)),
        ],
      ),
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final double progress;
  _BubblesPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = (1 - progress) * size.height + rnd.nextDouble() * 10;
      final r = 3 + rnd.nextDouble() * 6;
      final paint = Paint()..color = Colors.white.withOpacity(0.25);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ComicPager extends StatefulWidget {
  final List<String> story;
  final ValueChanged<int>? onPage;
  const _ComicPager({required this.story, this.onPage});
  @override
  State<_ComicPager> createState() => _ComicPagerState();
}

class _ComicPagerState extends State<_ComicPager> {
  final controller = PageController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: controller,
        itemCount: widget.story.length,
        onPageChanged: widget.onPage,
        itemBuilder: (context, i) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.bubble_chart_outlined, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.story[i])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RiverGameGrid extends StatelessWidget {
  final List<bool> trash;
  final ValueChanged<int> onClean;
  const _RiverGameGrid({required this.trash, required this.onClean});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemCount: trash.length,
        itemBuilder: (context, i) {
          final isTrash = trash[i];
          return GestureDetector(
            onTap: () => onClean(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isTrash ? Colors.brown.withOpacity(0.25) : Colors.green.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isTrash ? Colors.brown : Colors.greenAccent),
              ),
              child: Icon(isTrash ? Icons.delete_outline : Icons.check, color: isTrash ? Colors.brown : Colors.green),
            ),
          );
        },
      ),
    );
  }
}

class _FilterSteps extends StatefulWidget {
  final VoidCallback onComplete;
  const _FilterSteps({required this.onComplete});
  @override
  State<_FilterSteps> createState() => _FilterStepsState();
}

class _FilterStepsState extends State<_FilterSteps> {
  int step = 0;
  final steps = const [
    ('Step 1: Cloth pre-filter', 'Pour water through a clean cloth to remove big particles.'),
    ('Step 2: Sand & gravel', 'A bottle filter: gravel bottom, then sand, then cloth works well.'),
    ('Step 3: Activated carbon', 'Helps remove odors and some chemicals.'),
    ('Step 4: Disinfection', 'Boil OR UV OR properly-dosed chlorine.'),
    ('Step 5: Safe storage', 'Use clean, covered containers & avoid touching inside.'),
  ];

  void _next() {
    if (step < steps.length - 1) {
      setState(() => step++);
    } else {
      widget.onComplete();
      setState(() => step = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(steps[step].$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(steps[step].$2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: LinearProgressIndicator(value: (step+1)/steps.length)),
                const SizedBox(width: 12),
                FilledButton(onPressed: _next, child: Text(step == steps.length-1 ? 'Finish' : 'Next')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Task {
  final String title;
  bool done;
  _Task(this.title, this.done);
}
