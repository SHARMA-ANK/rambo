import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:rambo/models/bookmark_item.dart';
import 'package:rambo/providers/browser_provider.dart';
import 'package:rambo/screens/bookmarks_screen.dart';
import 'package:rambo/screens/history_screen.dart';
import 'package:rambo/screens/settings_screen.dart';
import 'package:rambo/services/database_service.dart';
import 'package:rambo/widgets/animated_logo.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  // We don't need local state for controller/url anymore, it's in the provider/tabs

  @override
  Widget build(BuildContext context) {
    return Consumer<BrowserProvider>(
      builder: (context, provider, child) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyT, control: true): () {
              provider.addTab();
            },
            const SingleActivator(LogicalKeyboardKey.keyW, control: true): () {
              if (provider.tabs.isNotEmpty) {
                provider.closeTab(provider.currentIndex);
              }
            },
            const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
              provider.currentTab?.controller?.reload();
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: _buildAppBar(context, provider),
              body: Column(
                children: [
                  _buildTabBar(context, provider),
                  // Removed standard linear progress indicator to replace with animated logo overlay below
                  Expanded(
                    child: Stack(
                      children: [
                        IndexedStack(
                          index: provider.currentIndex,
                          children: provider.tabs.map((tab) {
                            return _buildWebView(tab, provider);
                          }).toList(),
                        ),
                        if (provider.currentTab?.isLoading ?? false)
                          const Positioned(
                            bottom: 20,
                            right: 20,
                            child: Card(
                              elevation: 4,
                              shape: CircleBorder(),
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: AnimatedLogo(width: 40, height: 40),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    BrowserProvider provider,
  ) {
    // Note: Creating a new controller every build is bad for cursor position while typing,
    // but for now we sync strictly with the tab URL. Ideally this should be more robust.
    // For MVP, if the user is typing, we might not want to overwrite immediately unless navigation happens.
    // However, to keep it simple, we initialize it with the current URL.
    var textController = TextEditingController(
      text: provider.currentTab?.url ?? "",
    );

    return AppBar(
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: "Search or enter URL",
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            var url = Uri.parse(value);
            if (url.scheme.isEmpty) {
              url = Uri.parse("https://www.google.com/search?q=$value");
            }
            provider.currentTab?.controller?.loadUrl(
              urlRequest: URLRequest(url: WebUri.uri(url)),
            );
          },
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          provider.currentTab?.controller?.goBack();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            provider.currentTab?.controller?.goForward();
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            provider.currentTab?.controller?.reload();
          },
        ),
        // Bookmark Button
        IconButton(
          icon: Icon(
            provider.currentTab?.isBookmarked == true
                ? Icons.star
                : Icons.star_border,
            color: provider.currentTab?.isBookmarked == true
                ? Colors.amber
                : null,
          ),
          onPressed: () async {
            final tab = provider.currentTab;
            if (tab != null) {
              if (tab.isBookmarked) {
                // Ideally delete bookmark, but we need ID. For MVP we just toggle visual or handle complex logic in provider
                // Actually, let's just insert for now or implementing toggle is better.
                // Assuming URL is unique for bookmark for simplicity here
                // Delete logic usually requires ID or lookup
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Bookmark toggling not fully implemented yet",
                    ),
                  ),
                );
              } else {
                await DatabaseService().insertBookmark(
                  BookmarkItem(
                    url: tab.url,
                    title: tab.title,
                    createdTime: DateTime.now(),
                  ),
                );
                // Refresh status
                provider.updateTabUrl(tab.id, tab.url);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Bookmarked!")));
              }
            }
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'history') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const HistoryScreen()),
              );
            } else if (value == 'bookmarks') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const BookmarksScreen()),
              );
            } else if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SettingsScreen()),
              );
            } else if (value == 'about') {
              showDialog(
                context: context,
                builder: (context) => AboutDialog(
                  applicationName: 'Rambo Browser',
                  applicationVersion: '1.0.0',
                  applicationIcon: Image.asset(
                    'assets/rambo_browser.png',
                    width: 48,
                    height: 48,
                  ),
                  children: const [
                    Text('The cross-platform browsing experience.'),
                  ],
                ),
              );
            } else if (value == 'new_tab') {
              provider.addTab();
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem(
                value: 'new_tab',
                child: Row(
                  children: [
                    Icon(Icons.tab),
                    SizedBox(width: 8),
                    Text('New Tab'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bookmarks',
                child: Row(
                  children: [
                    Icon(Icons.bookmark),
                    SizedBox(width: 8),
                    Text('Bookmarks'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context, BrowserProvider provider) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.tabs.length,
        itemBuilder: (context, index) {
          final tab = provider.tabs[index];
          final isSelected = index == provider.currentIndex;
          return GestureDetector(
            onTap: () => provider.setCurrentIndex(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      tab.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => provider.closeTab(index),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebView(BrowserTab tab, BrowserProvider provider) {
    // We shouldn't recreate the WebView on every build, passing key might help?
    // In IndexedStack, widgets are kept alive.
    return InAppWebView(
      key: ValueKey(tab.id),
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
      initialSettings: InAppWebViewSettings(
        isInspectable: kDebugMode,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        iframeAllow: "camera; microphone",
        iframeAllowFullscreen: true,
      ),
      onWebViewCreated: (controller) {
        provider.setController(tab.id, controller);
      },
      onLoadStart: (controller, url) {
        provider.updateTabUrl(tab.id, url.toString());
        provider.updateTabProgress(tab.id, 0);
      },
      onPermissionRequest: (controller, request) async {
        return PermissionResponse(
          resources: request.resources,
          action: PermissionResponseAction.GRANT,
        );
      },
      onLoadStop: (controller, url) async {
        if (url != null) {
          provider.updateTabUrl(tab.id, url.toString());
          provider.recordHistory(url.toString(), tab.title);
        }
        provider.updateTabProgress(tab.id, 1.0);
      },
      onProgressChanged: (controller, progress) {
        provider.updateTabProgress(tab.id, progress / 100);
      },
      onTitleChanged: (controller, title) {
        if (title != null) {
          provider.updateTabTitle(tab.id, title);
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        if (url != null) {
          provider.updateTabUrl(tab.id, url.toString());
        }
      },
      onDownloadStartRequest: (controller, downloadStartRequest) async {
        await _downloadFile(
          downloadStartRequest.url.toString(),
          downloadStartRequest.suggestedFilename,
        );
      },
    );
  }

  Future<void> _downloadFile(String url, String? filename) async {
    // 1. Permission checks
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Permission denied")));
          }
          return;
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloading ${filename ?? 'file'}...")),
      );
    }

    try {
      Directory? dir;
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        dir = await getDownloadsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) return;

      final name =
          filename ?? "download_${DateTime.now().millisecondsSinceEpoch}";
      final String savePath = p.join(dir.path, name);

      var httpClient = HttpClient();
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = File(savePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saved to $savePath"),
            action: SnackBarAction(
              label: 'Open Folder',
              onPressed: () {
                // Implementing Open Folder logic requires url_launcher or native shell execution
                // For MVP we just notify.
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Download failed: $e")));
      }
    }
  }
}
