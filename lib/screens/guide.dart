import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': 'Boiling',
        'subtitle': 'Rolling boil for 1 minute (3 minutes at >2000m elevation).',
        'image': 'assets/images/boiling.png',
        'details': 'Boiling is a reliable method to kill most pathogens including bacteria, viruses and protozoa. Bring water to a full rolling boil for at least 1 minute. Use a covered pot and store boiled water in clean, covered containers.'
      },
      {
        'title': 'Chlorination',
        'subtitle': 'Use household bleach (5–6%). 2 drops per liter, wait 30 minutes.',
        'image': 'assets/images/chlorination.png',
        'details': 'Sodium hypochlorite (household bleach) can disinfect water when used correctly. Use fresh unscented bleach and follow dosage carefully. After adding, stir and let sit for at least 30 minutes. If water is cloudy, double the dose or pre-filter.'
      },
      {
        'title': 'Filtration',
        'subtitle': 'Use 0.2 μm filter + activated carbon for taste/odor.',
        'image': 'assets/images/filtration.png',
        'details': 'Mechanical filters remove particles and many pathogens depending on pore size. Ceramic and hollow-fiber filters are effective against protozoa and bacteria; use ultrafiltration or combined filters for viruses. Activated carbon improves taste and removes some chemicals.'
      },
      {
        'title': 'Ultraviolet (UV)',
        'subtitle': 'Portable UV pens deactivate microbes—pre-filter turbid water.',
        'image': 'assets/images/uv.png',
        'details': 'UV light is effective at inactivating bacteria and viruses when water is clear. Follow the device instructions, and pre-filter turbid water for best results.'
      },
      {
        'title': 'Activated Carbon',
        'subtitle': 'Removes taste, odor, and some organic contaminants.',
        'image': 'assets/images/activated_carbon.png',
        'details': 'Activated carbon does not disinfect biological contaminants by itself but is useful when used after disinfection to improve taste and remove organic chemicals and oils.'
      },
      {
        'title': 'Safe Storage',
        'subtitle': 'Keep water covered and use clean containers.',
        'image': 'assets/images/safe_storage.png',
        'details': 'Store treated water in clean, covered containers. Use a separate clean ladle for scooping water. Label containers and keep them off the ground to avoid contamination.'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Sanitation & Treatment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Practical Sanitation & Treatment Guide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('This guide expands on common methods to make water safer using home and community-level treatments. Follow local public health guidance for persistent or chemical contamination.'),
          const SizedBox(height: 16),
          for (final t in tips) Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(t['image']!, width: 84, height: 84, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(t['subtitle']!),
                  const SizedBox(height: 8),
                  Text(t['details']!, style: const TextStyle(color: Colors.black87)),
                ]))
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Step-by-step quick actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(child: ListTile(leading: const Icon(Icons.filter_alt), title: const Text('Pre-filter turbid water'), subtitle: const Text('Use cloth, coffee filter or settle & decant before disinfection'))),
          Card(child: ListTile(leading: const Icon(Icons.thermostat), title: const Text('Boil'), subtitle: const Text('Bring to rolling boil: 1 minute; 3 min above 2000m'))),
          Card(child: ListTile(leading: const Icon(Icons.bubble_chart), title: const Text('Use chlorine'), subtitle: const Text('Dose carefully: 2 drops/L (5–6% bleach) — wait 30 minutes'))),
          Card(child: ListTile(leading: const Icon(Icons.light), title: const Text('UV treatment'), subtitle: const Text('Use certified UV pens; keep water clear'))),
          const SizedBox(height: 12),
          const Text('When to seek lab testing', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('- Suspected chemical contamination (oil, solvents, heavy metals) — send to lab.\n- Recurrent illnesses in community after water use; unusual taste/odour; visible oil sheen; or algal scums.'),
          const SizedBox(height: 12),
          const Text('Illustrations', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final t in tips) Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(t['image']!, width: 96, height: 72, fit: BoxFit.cover)),
                    const SizedBox(height: 6),
                    Text(t['title']!, style: const TextStyle(fontSize: 12))
                  ]),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
