class Player {
  const Player({required this.name, required this.photoUrl, this.isActive = false});

  final String name;
  final String photoUrl;
  final bool isActive;

  Player copyWith({String? name, String? photoUrl, bool? isActive}) {
    return Player(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
