import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rambo/providers/theme_provider.dart';
import 'package:rambo/services/database_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeText(themeProvider.themeMode)),
                leading: const Icon(Icons.brightness_6),
                trailing: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Default'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      themeProvider.setThemeMode(newValue);
                    }
                  },
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Data & Privacy'),
          ListTile(
            title: const Text('Clear History'),
            leading: const Icon(Icons.history),
            onTap: () async {
              _showClearDataDialog(context, 'History', () async {
                await DatabaseService().clearHistory();
              });
            },
          ),
          ListTile(
            title: const Text('Clear All Bookmarks'),
            leading: const Icon(Icons.bookmark_remove),
            onTap: () async {
              // For now, not implementing clear all bookmarks in service yet,
              // but placeholder for future.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Clear all bookmarks not implemented yet."),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            title: Text('Rambo Browser'),
            subtitle: Text('Version 1.0.0'),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follows system settings';
      case ThemeMode.light:
        return 'Always light';
      case ThemeMode.dark:
        return 'Always dark';
    }
  }

  Future<void> _showClearDataDialog(
    BuildContext context,
    String dataType,
    VoidCallback onConfirm,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear $dataType?"),
        content: Text(
          "Are you sure you want to delete all your $dataType? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("$dataType cleared.")));
            },
          ),
        ],
      ),
    );
  }
}
