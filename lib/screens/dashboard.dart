
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Widget _tile(BuildContext context, IconData icon, String title, String route) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed(route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aqua Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, Icons.analytics, 'AI Analysis', '/analysis'),
          _tile(context, Icons.shield_moon_outlined, 'Sanitation & Treatment', '/guide'),
          _tile(context, Icons.history, 'History', '/history'),
          _tile(context, Icons.group, 'Community Reports', '/reports'),
          _tile(context, Icons.quiz_outlined, 'Quiz & Badges', '/quiz'),
          _tile(context, Icons.child_care, 'Kids Corner', '/kids'),
          _tile(context, Icons.settings, 'Settings', '/settings'),
        ],
      ),
    );
  }
}
