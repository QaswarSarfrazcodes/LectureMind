class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.preferredLanguage = 'en',
    required this.createdAt,
    this.isAnonymous = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String preferredLanguage;
  final DateTime createdAt;
  final bool isAnonymous;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? preferredLanguage,
    DateTime? createdAt,
    bool? isAnonymous,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        createdAt: createdAt ?? this.createdAt,
        isAnonymous: isAnonymous ?? this.isAnonymous,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        if (photoUrl != null) 'photo_url': photoUrl,
        'preferred_language': preferredLanguage,
        'created_at': createdAt.toIso8601String(),
        'is_anonymous': isAnonymous,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        preferredLanguage: json['preferred_language'] as String? ?? 'en',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        isAnonymous: json['is_anonymous'] as bool? ?? false,
      );
}
