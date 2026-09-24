// Will Contain UserDetails Translate From GoogleUser

class User {
  final String id;

  final String email;

  final String? displayName;

  final String? imageUrl;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.imageUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
