import 'dart:convert';

/// Different categories of rounds to help diversify gameplay.
enum RoundCategory {
  warmup,
  challenge,
  story,
  skill,
  wildcard;

  factory RoundCategory.fromJson(String value) {
    return RoundCategory.values.firstWhere(
      (category) => category.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RoundCategory.wildcard,
    );
  }

  String get label => switch (this) {
    RoundCategory.warmup => 'Warm-up',
    RoundCategory.challenge => 'Challenge',
    RoundCategory.story => 'Story',
    RoundCategory.skill => 'Skill Check',
    RoundCategory.wildcard => 'Wildcard',
  };

  /// Categories that keep the same task until a player completes it.
  bool get persistsUntilSuccess => switch (this) {
    RoundCategory.challenge || RoundCategory.skill => true,
    _ => false,
  };
}

class Round {
  Round({
    required this.id,
    required this.title,
    required this.taskDescription,
    required this.category,
    this.rewardDescription,
    this.punishmentDescription,
    this.taskVideoPath,
    this.taskPhotoPath,
    this.rewardVideoPath,
    this.rewardPhotoPath,
    this.playerId,
  });

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      id: json['id'] as String,
      title: json['title'] as String,
      taskDescription: json['taskDescription'] as String,
      rewardDescription: json['rewardDescription'] as String?,
      punishmentDescription: json['punishmentDescription'] as String?,
      category: RoundCategory.fromJson(json['category'] as String),
      taskVideoPath: json['taskVideoPath'] as String?,
      taskPhotoPath: json['taskPhotoPath'] as String?,
      rewardVideoPath: json['rewardVideoPath'] as String?,
      rewardPhotoPath: json['rewardPhotoPath'] as String?,
      playerId: json['playerId'] as String?,
    );
  }

  final String id;
  final String title;
  final String taskDescription;
  final String? rewardDescription;
  final String? punishmentDescription;
  final RoundCategory category;
  final String? taskVideoPath;
  final String? taskPhotoPath;
  final String? rewardVideoPath;
  final String? rewardPhotoPath;
  final String? playerId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'taskDescription': taskDescription,
      'rewardDescription': rewardDescription,
      'punishmentDescription': punishmentDescription,
      'category': category.name,
      'taskVideoPath': taskVideoPath,
      'taskPhotoPath': taskPhotoPath,
      'rewardVideoPath': rewardVideoPath,
      'rewardPhotoPath': rewardPhotoPath,
      'playerId': playerId,
    };
  }
}

List<Round> decodeRounds(String jsonStr) {
  final data = json.decode(jsonStr) as List<dynamic>;
  return data.map((element) => Round.fromJson(element as Map<String, dynamic>)).toList();
}
