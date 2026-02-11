import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rambo/models/history_item.dart';
import 'package:rambo/services/database_service.dart';

class BrowserTab {
  final String id;
  String url;
  String title;
  InAppWebViewController? controller;
  double progress;
  bool isLoading;
  bool isBookmarked; // Cache bookmark status

  BrowserTab({
    required this.id,
    this.url = 'https://google.com',
    this.title = 'New Tab',
    this.progress = 0,
    this.isLoading = false,
    this.isBookmarked = false,
  });
}

class BrowserProvider extends ChangeNotifier {
  final List<BrowserTab> _tabs = [];
  int _currentIndex = 0;
  final DatabaseService _dbService = DatabaseService();

  List<BrowserTab> get tabs => _tabs;
  int get currentIndex => _currentIndex;
  BrowserTab? get currentTab => _tabs.isNotEmpty ? _tabs[_currentIndex] : null;

  BrowserProvider() {
    // Start with one tab
    addTab();
  }

  void addTab({String url = 'https://google.com'}) {
    _tabs.add(
      BrowserTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
      ),
    );
    _currentIndex = _tabs.length - 1;
    notifyListeners();
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close the last tab, just reset it
      _tabs[0].url = 'https://google.com';
      _tabs[0].title = 'New Tab';
      _tabs[0].controller?.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://google.com')),
      );
      notifyListeners();
      return;
    }

    _tabs.removeAt(index);
    if (_currentIndex >= _tabs.length) {
      _currentIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void updateTabProgress(String id, double progress) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].progress = progress;
      _tabs[index].isLoading = progress < 1.0;
      notifyListeners();
    }
  }

  Future<void> updateTabUrl(String id, String url) async {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].url = url;
      // Check if bookmarked
      final bookmarked = await _dbService.isBookmarked(url);
      _tabs[index].isBookmarked = bookmarked;

      notifyListeners();
    }
  }

  void recordHistory(String url, String title) {
    if (url.isNotEmpty && url != "about:blank") {
      _dbService.insertHistory(
        HistoryItem(url: url, title: title, visitTime: DateTime.now()),
      );
    }
  }

  void updateTabTitle(String id, String title) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].title = title;
      notifyListeners();
    }
  }

  void setController(String id, InAppWebViewController controller) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].controller = controller;
    }
  }
}
