class User {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String createdAt;
}
