import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rambo/models/bookmark_item.dart';
import 'package:rambo/providers/browser_provider.dart';
import 'package:rambo/services/database_service.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<BookmarkItem> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final items = await _dbService.getBookmarks();
    setState(() {
      _bookmarks = items;
      _isLoading = false;
    });
  }

  Future<void> _deleteBookmark(int id) async {
    await _dbService.deleteBookmark(id);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
          ? const Center(child: Text("No bookmarks yet"))
          : ListView.builder(
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final item = _bookmarks[index];
                return ListTile(
                  leading: const Icon(Icons.bookmark),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteBookmark(item.id!),
                  ),
                  onTap: () {
                    final provider = Provider.of<BrowserProvider>(
                      context,
                      listen: false,
                    );
                    provider.addTab(url: item.url);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}
