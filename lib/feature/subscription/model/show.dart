class Show {
  final String id;

  final String title;

  final String description;

  final String? thumbnailUrl;

  Show({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
  };

  factory Show.fromJson(Map<String, dynamic> map) => Show(
    id: map['id'],
    title: map['title'],
    thumbnailUrl: map['thumbnailUrl'],
    description: map['description'],
  );
}
