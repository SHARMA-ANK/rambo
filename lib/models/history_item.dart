class HistoryItem {
  final int? id;
  final String url;
  final String title;
  final DateTime visitTime;

  HistoryItem({
    this.id,
    required this.url,
    required this.title,
    required this.visitTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'visitTime': visitTime.millisecondsSinceEpoch,
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'],
      url: map['url'],
      title: map['title'],
      visitTime: DateTime.fromMillisecondsSinceEpoch(map['visitTime']),
    );
  }
}
