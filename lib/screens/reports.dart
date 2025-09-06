
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CommunityReportsScreen extends StatefulWidget {
  CommunityReportsScreen({super.key});

  @override
  State<CommunityReportsScreen> createState() => _CommunityReportsScreenState();
}

class _CommunityReportsScreenState extends State<CommunityReportsScreen> {
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reports') ?? '[]';
    setState(() => reports = List<Map<String, dynamic>>.from(json.decode(raw)));
  }

  Future<void> _addReport() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New report'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Brief note (e.g., muddy, odor)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (note == null || note.isEmpty) return;
    final item = {'note': note, 'time': DateTime.now().toIso8601String()};
    final prefs = await SharedPreferences.getInstance();
    reports.insert(0, item);
    await prefs.setString('reports', json.encode(reports));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Reports')),
      floatingActionButton: FloatingActionButton(onPressed: _addReport, child: const Icon(Icons.add)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, i) {
          final r = reports[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(r['note'] ?? ''),
              subtitle: Text(DateTime.parse(r['time']).toLocal().toString()),
            ),
          );
        },
      ),
    );
  }
}
