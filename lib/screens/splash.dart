
import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wave;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _wave = Tween<double>(begin: 0.0, end: 8.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _wave,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary
                    ]),
                    boxShadow: const [BoxShadow(blurRadius: 20, spreadRadius: 2, color: Colors.black45)],
                  ),
                  child: CustomPaint(painter: _WavePainter(_wave.value)),
                ),
                const SizedBox(height: 18),
                Text("Aqua Insights", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("Smart water safety assistant"),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double v;
  _WavePainter(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.85);
    final path = Path();
    final h = size.height;
    final w = size.width;
    path.moveTo(0, h*0.6);
    for (double x = 0; x <= w; x++) {
      final y = h*0.6 + 6 * (1.0 + (x/20 + v)).sin();
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.v != v;
}

extension _Sin on double {
  double sin() => Math.sin(this);
}

class Math {
  static double sin(double x) => Math._sinApprox(x);
  static double _sinApprox(double x) {
    while (x > 3.14159265) { x -= 6.2831853; }
    while (x < -3.14159265) { x += 6.2831853; }
    final x3 = x*x*x;
    final x5 = x3*x*x;
    return x - (x3/6) + (x5/120);
  }
}
