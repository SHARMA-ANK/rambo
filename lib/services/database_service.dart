import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rambo/models/history_item.dart';
import 'package:rambo/models/bookmark_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows/Desktop
    if (kIsWeb) {
      // Handle web separately if needed (not using sqflite for web usually)
      throw Exception("Web not supported by this implementation yet");
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (Platform.isWindows || Platform.isLinux) {
      // Use support directory for desktop
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, 'rambo_browser.db');
    } else {
      path = join(await getDatabasesPath(), 'rambo_browser.db');
    }

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT,
        title TEXT,
        visitTime INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT,
        title TEXT,
        createdTime INTEGER
      )
    ''');
  }

  // History Operations
  Future<int> insertHistory(HistoryItem item) async {
    final db = await database;
    // Check if url exists recently? (Optional optimization)
    // For now, simple insert
    return await db.insert('history', item.toMap());
  }

  Future<List<HistoryItem>> getHistory({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'history',
      orderBy: 'visitTime DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => HistoryItem.fromMap(maps[i]));
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }

  // Bookmark Operations
  Future<int> insertBookmark(BookmarkItem item) async {
    final db = await database;
    return await db.insert('bookmarks', item.toMap());
  }

  Future<void> deleteBookmark(int id) async {
    final db = await database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookmarkItem>> getBookmarks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      orderBy: 'createdTime DESC',
    );
    return List.generate(maps.length, (i) => BookmarkItem.fromMap(maps[i]));
  }

  Future<bool> isBookmarked(String url) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'url = ?',
      whereArgs: [url],
    );
    return result.isNotEmpty;
  }
}
