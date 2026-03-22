class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String category;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.category,
    required this.createdAt,
  });

  factory Event.fromFirestore(Map<String, dynamic> data, String id) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date:
          data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
      location: data['location'] ?? '',
      category: data['category'] ?? 'General',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
