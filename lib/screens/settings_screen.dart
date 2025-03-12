// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../widgets/universal_navigation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _handleThemeChange(BuildContext context, String? val) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme change feature not implemented yet.'),
      ),
    );
  }

  void _handleCloudToggle(BuildContext context, bool val) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cloud toggle feature not implemented yet.'),
      ),
    );
  }

  void _handleClearCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      // Use UniversalNavigation as the top AppBar.
      appBar: const UniversalNavigation(currentIndex: 2, pageTitle: 'Settings'),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens, color: Colors.deepPurple),
            title: const Text('Theme Mode'),
            trailing: DropdownButton<String>(
              value: 'System',
              items:
                  ['Light', 'Dark', 'System']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (val) => _handleThemeChange(context, val),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.deepPurple),
            title: const Text('Upload recordings to cloud'),
            trailing: Switch(
              value: false,
              onChanged: (val) => _handleCloudToggle(context, val),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.deepPurple),
            title: const Text('Clear cache'),
            onTap: () => _handleClearCache(context),
          ),
        ],
      ),
    );
  }
}
