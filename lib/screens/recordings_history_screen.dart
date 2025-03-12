// lib/screens/recordings_history_screen.dart
import 'package:flutter/material.dart';
import '../widgets/universal_navigation.dart';

class RecordingsHistoryScreen extends StatelessWidget {
  const RecordingsHistoryScreen({super.key});

  // Dummy recordings for demonstration.
  final List<Map<String, String>> dummyRecordings = const [
    {
      'title': 'Recording 1',
      'date': '2025-02-01',
      'summary': 'Discussing project requirements and timelines.',
    },
    {
      'title': 'Recording 2',
      'date': '2025-02-05',
      'summary': 'Brainstorm session on new marketing strategies.',
    },
    {
      'title': 'Recording 3',
      'date': '2025-02-10',
      'summary': 'Update on budget and financial forecasts.',
    },
    {
      'title': 'Recording 4',
      'date': '2025-02-14',
      'summary': 'Brief conversation about upcoming team events.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      // Use UniversalNavigation as the top AppBar.
      // Using currentIndex: 3 to indicate that this page is not part of the main menu.
      appBar: const UniversalNavigation(
        currentIndex: 3,
        pageTitle: 'Previous Recordings',
      ),
      body: ListView.builder(
        itemCount: dummyRecordings.length,
        itemBuilder: (context, index) {
          final recording = dummyRecordings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.file_present, color: Colors.deepPurple),
              title: Text(recording['title'] ?? 'No Title'),
              subtitle: Text(
                'Date: ${recording['date']}\nSummary: ${recording['summary']}',
              ),
              isThreeLine: true,
              onTap: () {
                // Provide immediate feedback.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playback feature not implemented yet.'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
