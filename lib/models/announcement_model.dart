class Announcement {
  final String id;
  final String title;
  final String message;
  final String category;
  final String postedBy;
  final DateTime createdAt;
  final bool isPinned;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.postedBy,
    required this.createdAt,
    this.isPinned = false,
  });

  factory Announcement.fromFirestore(Map<String, dynamic> data, String id) {
    return Announcement(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'General',
      postedBy: data['postedBy'] ?? '',
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'category': category,
      'postedBy': postedBy,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }
}
