import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rambo/models/history_item.dart';
import 'package:rambo/providers/browser_provider.dart';
import 'package:rambo/services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<HistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final items = await _dbService.getHistory();
    setState(() {
      _history = items;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await _dbService.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear History"),
                  content: const Text(
                    "Are you sure you want to clear your browsing history?",
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text(
                        "Clear",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        _clearHistory();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(child: Text("No history yet"))
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  title: Text(
                    item.title.isNotEmpty ? item.title : item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat.yMMMd().add_jm().format(item.visitTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    final provider = Provider.of<BrowserProvider>(
                      context,
                      listen: false,
                    );
                    provider.addTab(url: item.url);
                    Navigator.pop(context); // Go back to browser
                  },
                );
              },
            ),
    );
  }
}
