class Bulletin {
  final String id;
  final String title;
  final String serviceDate;
  final String serviceTime;
  final String preacher;
  final String sermonTopic;
  final String bibleReading;
  final List<String> programItems;
  final List<String> announcements;
  final String closingVerse;
  final DateTime createdAt;

  Bulletin({
    required this.id,
    required this.title,
    required this.serviceDate,
    required this.serviceTime,
    required this.preacher,
    required this.sermonTopic,
    required this.bibleReading,
    required this.programItems,
    required this.announcements,
    required this.closingVerse,
    required this.createdAt,
  });

  factory Bulletin.fromFirestore(Map<String, dynamic> data, String id) {
    return Bulletin(
      id: id,
      title: data['title'] ?? '',
      serviceDate: data['serviceDate'] ?? '',
      serviceTime: data['serviceTime'] ?? '',
      preacher: data['preacher'] ?? '',
      sermonTopic: data['sermonTopic'] ?? '',
      bibleReading: data['bibleReading'] ?? '',
      programItems: List<String>.from(data['programItems'] ?? []),
      announcements: List<String>.from(data['announcements'] ?? []),
      closingVerse: data['closingVerse'] ?? '',
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'serviceDate': serviceDate,
      'serviceTime': serviceTime,
      'preacher': preacher,
      'sermonTopic': sermonTopic,
      'bibleReading': bibleReading,
      'programItems': programItems,
      'announcements': announcements,
      'closingVerse': closingVerse,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
