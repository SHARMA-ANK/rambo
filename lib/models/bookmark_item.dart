class BookmarkItem {
  final int? id;
  final String url;
  final String title;
  final DateTime createdTime;

  BookmarkItem({
    this.id,
    required this.url,
    required this.title,
    required this.createdTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'createdTime': createdTime.millisecondsSinceEpoch,
    };
  }

  factory BookmarkItem.fromMap(Map<String, dynamic> map) {
    return BookmarkItem(
      id: map['id'],
      url: map['url'],
      title: map['title'],
      createdTime: DateTime.fromMillisecondsSinceEpoch(map['createdTime']),
    );
  }
}
