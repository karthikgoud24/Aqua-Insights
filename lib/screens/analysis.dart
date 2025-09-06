// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Uint8List? _imageBytes;
  Map<String, dynamic>? _results;
  bool _busy = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await _picker.pickImage(
        source: src,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _results = null;
      });
      await _analyze(bytes);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image pick failed: $e")));
    }
  }

  /// Analyze a provided byte buffer of an image.
  Future<void> _analyze(Uint8List bytes) async {
    setState(() { _busy = true; _results = null; });

    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception("Unable to decode image.");
      final w = decoded.width;
      final h = decoded.height;

      // Downsampled scan to keep CPU low
      const maxSamples = 60000;
      final step = math.max(1, (math.sqrt((w * h) / maxSamples)).floor());

      int total = 0;
      double sumLum = 0.0;
      double edgeAcc = 0.0;
      int highSatCount = 0;
      int greenishCount = 0;
      int brightSpots = 0;
      int darkSpots = 0;
      double hueSum = 0.0;
      double hueSqSum = 0.0;

      int? prevR, prevG, prevB;

      for (int y = 0; y < h; y += step) {
        for (int x = 0; x < w; x += step) {
          total++;
          final px = decoded.getPixelSafe(x, y);
          final r = px.r.toInt();
          final g = px.g.toInt();
          final b = px.b.toInt();

          // luminance (0..1)
          final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
          sumLum += lum;

          // simple edge/texture metric as delta from last pixel
          if (prevR != null) {
            edgeAcc += ((r - prevR!).abs() + (g - prevG!).abs() + (b - prevB!).abs()) / 765.0;
          }
          prevR = r; prevG = g; prevB = b;

          // saturation & hue
          final maxc = math.max(r, math.max(g, b)).toDouble();
          final minc = math.min(r, math.min(g, b)).toDouble();
          final delta = maxc - minc;
          final sat = maxc == 0 ? 0.0 : (delta / maxc);
          double hue = 0.0;
          if (delta != 0) {
            if (maxc == r) hue = ((g - b) / delta) % 6;
            else if (maxc == g) hue = ((b - r) / delta) + 2;
            else hue = ((r - g) / delta) + 4;
            hue = hue / 6.0; // 0..1
          }
          hueSum += hue;
          hueSqSum += hue * hue;

          if (sat > 0.55 && maxc / 255.0 > 0.6) highSatCount++;
          if (g > r * 1.12 && g > b * 1.12 && g > 80) greenishCount++;
          if (lum > 0.92) brightSpots++;
          if (lum < 0.06) darkSpots++;
        }
      }

      // metrics
      final avgLum = sumLum / math.max(1, total);
      final edgeMetric = edgeAcc / math.max(1, total);
      final highSatRatio = highSatCount / math.max(1, total);
      final greenRatio = greenishCount / math.max(1, total);
      final brightRatio = brightSpots / math.max(1, total);
      final darkRatio = darkSpots / math.max(1, total);
      final hueMean = hueSum / math.max(1, total);
      final hueVar = (hueSqSum / math.max(1, total)) - (hueMean * hueMean);

      // Heuristics (0..1)
      final oilScore = (highSatRatio * 3.0).clamp(0.0, 1.0) * ( (hueVar * 8.0).clamp(0.0,1.0) );
      double turbidityScore = (1.0 - edgeMetric.clamp(0.0, 1.0)) * (1.0 - (avgLum.clamp(0.0, 1.0)));
      turbidityScore = turbidityScore.clamp(0.0, 1.0);
      final algaeScore = (greenRatio * 6.0).clamp(0.0, 1.0) * ((avgLum > 0.08) ? 1.0 : 0.8);
      final particleScore = (brightRatio * 30.0).clamp(0.0, 1.0);

      // Purity score (simple inverse of contaminants, 0..100)
      double purity = 100.0;
      purity -= (oilScore * 32.0);
      purity -= (turbidityScore * 28.0);
      purity -= (algaeScore * 25.0);
      purity -= (particleScore * 15.0);
      purity = purity.clamp(0.0, 100.0);

      final bool possibleBio = (algaeScore > 0.25) || (turbidityScore > 0.45) || (particleScore > 0.25);

      final result = <String, dynamic>{
        'purity': purity,
        'oil': (oilScore * 100).round(),
        'turbidity': (turbidityScore * 100).round(),
        'algae': (algaeScore * 100).round(),
        'particles': (particleScore * 100).round(),
        'avg_luminance': avgLum,
        'edge_metric': edgeMetric,
        'high_sat_ratio': highSatRatio,
        'green_ratio': greenRatio,
        'bright_ratio': brightRatio,
        'dark_ratio': darkRatio,
        'hue_var': hueVar,
        'possible_bio': possibleBio,
      };

      setState(() { _results = result; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
    } finally {
      setState(() { _busy = false; });
    }
  }

  /// Run a demo analysis on a generated test image (no asset dependency).
  Future<void> _analyzeDemo() async {
    final demo = img.Image(width: 480, height: 360);
    // Create a soft blue/green gradient with a few bright specks (simulate particles).
    for (int y = 0; y < demo.height; y++) {
      for (int x = 0; x < demo.width; x++) {
        final t = y / demo.height;
        final r = (10 + 10 * t).toInt();
        final g = (160 + 40 * t).toInt();
        final b = (210 - 30 * t).toInt();
        demo.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    // add bright specks
    for (int i = 0; i < 600; i++) {
      final x = (math.Random().nextDouble() * demo.width).toInt();
      final y = (math.Random().nextDouble() * demo.height).toInt();
      demo.setPixelRgba(x, y, 255, 255, 255, 255);
    }
    final bytes = Uint8List.fromList(img.encodePng(demo));
    setState(() { _imageBytes = bytes; _results = null; });
    await _analyze(bytes);
  }

  Widget _headerTile() {
    return ListTile(
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF00D4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.upload, color: Colors.black, size: 26),
      ),
      title: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Pick or snap a clear photo of the water in a white/transparent cup. Avoid reflections.'),
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _analyzeDemo,
            icon: const Icon(Icons.camera),
            label: Text(_busy ? 'Analyzing…' : 'Analyze demo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
              foregroundColor: const Color(0xFF0F1724),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pick photo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: Color(0xFF00D4FF)),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(bool ok, double purity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B5B73).withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ok ? const Color(0xFF00D4FF) : Colors.orange,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.check_circle, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ok ? 'Looks like water' : 'Unclear sample',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Purity score: ${purity.toStringAsFixed(1)}%'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );

  Widget _hazardBlock({required String heading, required String body, required String hazard, required String fix}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body),
        const SizedBox(height: 10),
        Row(children: const [
          Icon(Icons.shield_outlined, size: 18),
          SizedBox(width: 6),
          Text('Hazards', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(hazard),
        const SizedBox(height: 8),
        Row(children: const [
          Icon(Icons.tips_and_updates_outlined, size: 18),
          SizedBox(width: 6),
          Text('How to fix', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Text(fix),
      ]),
    );
  }

  Widget _resultsView() {
    final r = _results!;
    final purity = (r['purity'] as num).toDouble();
    final ok = purity >= 40.0; // just a label threshold
    final oil = r['oil'] as int;
    final turb = r['turbidity'] as int;
    final algae = r['algae'] as int;
    final parts = r['particles'] as int;

    final children = <Widget>[
      _pill(ok, purity),
      _sectionTitle('Detected Impurities'),
      _hazardBlock(
        heading: 'Not image-detectable hazards',
        body: 'Substances like pesticides, heavy metals (lead, arsenic) or radioactivity cannot be reliably detected from a photo.',
        hazard: 'May cause serious long-term health effects.',
        fix: 'Use certified test kits or lab analysis; rely on local water quality reports.',
      ),
    ];

    if (algae >= 15) {
      children.add(_hazardBlock(
        heading: 'Algae (possible cyanobacteria)',
        body: 'Greenish tint suggests algal growth. Often occurs in standing water with sunlight exposure.',
        hazard: 'May produce toxins causing skin irritation, vomiting.',
        fix: 'Shock chlorinate, avoid ingestion, filter + UV treatment.',
      ));
    }
    if (oil >= 15) {
      children.add(_hazardBlock(
        heading: 'Possible Oil/Chemical Sheen',
        body: 'Iridescent rainbow-like colors on bright areas may indicate an oil film or detergents.',
        hazard: 'Can irritate skin; hydrocarbons are harmful if ingested.',
        fix: 'Avoid ingestion; skim/remove film; use absorbent pads; contact local authorities for spills.',
      ));
    }
    if (turb >= 20) {
      children.add(_hazardBlock(
        heading: 'Turbidity (cloudiness)',
        body: 'Low contrast / cloudy appearance indicates suspended solids.',
        hazard: 'May harbor microbes and reduce effectiveness of disinfection.',
        fix: 'Pre-filter (cloth/ceramic), then disinfect (boil 1–3 min, chlorine, or UV).',
      ));
    }
    if (parts >= 15) {
      children.add(_hazardBlock(
        heading: 'Particles / Foam',
        body: 'Bright speckles or foam-like patches detected.',
        hazard: 'May indicate debris or surfactants; can irritate stomach/skin.',
        fix: 'Use fine mechanical filtration and disinfect.',
      ));
    }

    // biological reminder
    children.add(_hazardBlock(
      heading: 'Biological contamination & bacteria',
      body: 'Photos cannot detect bacteria species.',
      hazard: 'Diarrhea, vomiting, fever may occur if contaminated water is consumed.',
      fix: 'Use 0.1–0.2 μm filters or boil; for certainty, test with kits or a lab.',
    ));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Analysis')),
      body: Column(
        children: [
          const SizedBox(height: 6),
          _headerTile(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _actionButtons(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : (_results == null
                      ? Center(
                          child: Text(
                            'Pick or analyze a photo to see results',
                            style: theme.textTheme.bodyLarge,
                          ),
                        )
                      : _resultsView()),
            ),
          ),
        ],
      ),
      floatingActionButton: _imageBytes == null ? null : FloatingActionButton.extended(
        onPressed: _busy ? null : () => _analyze(_imageBytes!),
        label: Text(_busy ? 'Analyzing…' : 'Re-run analysis'),
        icon: const Icon(Icons.analytics_outlined),
      ),
    );
  }
}
