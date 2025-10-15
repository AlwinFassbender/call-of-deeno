import 'dart:typed_data';

class Player {
  const Player({required this.name, this.photoAsset, this.photoBytes, this.isActive = true});

  final String name;
  final String? photoAsset;
  final Uint8List? photoBytes;
  final bool isActive;

  static const String defaultAvatarAsset = 'assets/images/players/default.png';

  Player copyWith({String? name, String? photoAsset, Uint8List? photoBytes, bool? isActive}) {
    return Player(
      name: name ?? this.name,
      photoAsset: photoAsset ?? this.photoAsset,
      photoBytes: photoBytes ?? this.photoBytes,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] as String,
      photoAsset: json['image'] as String?,
      isActive: (json['isActive'] as bool?) ?? false,
    );
  }
}
