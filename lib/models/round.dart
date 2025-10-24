import 'dart:convert';

/// Different categories of rounds to help diversify gameplay.
enum RoundCategory {
  /// Self explanatory
  neverHaveIEver,

  /// Vote one person of the group
  vote,

  /// The group decides which of the options is best
  groupDecision,

  /// Each person has to name something from that category
  categories,

  /// Each person fulfilling that criterion
  criteria,

  /// Someone has to take a guess
  guess,

  /// Two people battle it out
  duel,

  task,

  /// Other
  other;

  factory RoundCategory.fromJson(String value) {
    return RoundCategory.values.firstWhere(
      (category) => category.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RoundCategory.other,
    );
  }

  bool get persistsUntilSuccess => switch (this) {
    RoundCategory.guess => true,
    _ => false,
  };

  String get label => switch (this) {
    RoundCategory.neverHaveIEver => 'Never Have I Ever',
    RoundCategory.vote => 'Vote',
    RoundCategory.groupDecision => 'Group Decision',
    RoundCategory.categories => 'Categories',
    RoundCategory.criteria => 'Criteria',
    RoundCategory.guess => 'Guess',
    RoundCategory.task => 'Task',
    RoundCategory.duel => 'Duel',
    RoundCategory.other => 'Wildcard',
  };
}

enum RoundRepeatBehavior { once, repeatWithLimit, repeatUnlimited }

class Round {
  Round({
    required this.id,
    required this.title,
    required this.taskDescription,
    required this.category,
    required this.repeatBehavior,
    this.rewardDescription,
    this.punishmentDescription,
    this.taskVideoPath,
    this.taskPhotoPath,
    this.rewardVideoPath,
    this.rewardPhotoPath,
    this.maxRepeats,
    this.cooldownRounds,
    List<String>? playerIds,
  }) : playerIds = playerIds ?? const [];

  factory Round.fromJson(Map<String, dynamic> json) {
    final dynamic rawPlayerIds = json['playerIds'] ?? json['playerId'];
    final List<String> parsedPlayerIds;
    if (rawPlayerIds is List) {
      parsedPlayerIds = rawPlayerIds.whereType<String>().toList();
    } else if (rawPlayerIds is String) {
      parsedPlayerIds = [rawPlayerIds];
    } else {
      parsedPlayerIds = const [];
    }

    return Round(
      id: json['id'] as String,
      title: json['title'] as String,
      taskDescription: json['taskDescription'] as String,
      rewardDescription: json['rewardDescription'] as String?,
      punishmentDescription: json['punishmentDescription'] as String?,
      category: RoundCategory.fromJson(json['category'] as String),
      repeatBehavior: _repeatBehaviorFromJson(json['repeatBehavior'] as String?),
      taskVideoPath: json['taskVideoPath'] as String?,
      taskPhotoPath: json['taskPhotoPath'] as String?,
      rewardVideoPath: json['rewardVideoPath'] as String?,
      rewardPhotoPath: json['rewardPhotoPath'] as String?,
      maxRepeats: (json['maxRepeats'] as num?)?.toInt(),
      cooldownRounds: (json['cooldownRounds'] as num?)?.toInt(),
      playerIds: parsedPlayerIds,
    );
  }

  final String id;
  final String title;
  final String taskDescription;
  final String? rewardDescription;
  final String? punishmentDescription;
  final RoundCategory category;
  final RoundRepeatBehavior repeatBehavior;
  final String? taskVideoPath;
  final String? taskPhotoPath;
  final String? rewardVideoPath;
  final String? rewardPhotoPath;
  final int? maxRepeats;
  final int? cooldownRounds;
  final List<String> playerIds;

  bool get needsPlayers => requiredPlayerCount > 0;

  int get requiredPlayerCount => switch (category) {
    RoundCategory.guess => 1,
    RoundCategory.duel => 2,
    _ => 0,
  };

  bool get isFinite => repeatBehavior != RoundRepeatBehavior.repeatUnlimited;

  double get targetPlayWeight {
    return switch (repeatBehavior) {
      RoundRepeatBehavior.once => 1,
      RoundRepeatBehavior.repeatWithLimit => (maxRepeats ?? 1).clamp(1, 10).toDouble(),
      RoundRepeatBehavior.repeatUnlimited => 0.6,
    };
  }

  double get finitePlayQuota {
    return switch (repeatBehavior) {
      RoundRepeatBehavior.once => 1,
      RoundRepeatBehavior.repeatWithLimit => (maxRepeats ?? 1).clamp(1, 100).toDouble(),
      RoundRepeatBehavior.repeatUnlimited => 0,
    };
  }

  int get effectiveMaxRepeats => switch (repeatBehavior) {
    RoundRepeatBehavior.once => 1,
    RoundRepeatBehavior.repeatWithLimit => (maxRepeats ?? 1).clamp(1, 100),
    RoundRepeatBehavior.repeatUnlimited => 0,
  };

  bool isExhausted(int playCount) {
    return switch (repeatBehavior) {
      RoundRepeatBehavior.once => playCount >= 1,
      RoundRepeatBehavior.repeatWithLimit => playCount >= effectiveMaxRepeats,
      RoundRepeatBehavior.repeatUnlimited => false,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'taskDescription': taskDescription,
      'rewardDescription': rewardDescription,
      'punishmentDescription': punishmentDescription,
      'category': category.name,
      'repeatBehavior': repeatBehavior.name,
      'maxRepeats': maxRepeats,
      'cooldownRounds': cooldownRounds,
      'taskVideoPath': taskVideoPath,
      'taskPhotoPath': taskPhotoPath,
      'rewardVideoPath': rewardVideoPath,
      'rewardPhotoPath': rewardPhotoPath,
      'playerIds': playerIds,
    };
  }
}

RoundRepeatBehavior _repeatBehaviorFromJson(String? value) {
  if (value == null) {
    return RoundRepeatBehavior.once;
  }
  return RoundRepeatBehavior.values.firstWhere(
    (behavior) => behavior.name.toLowerCase() == value.toLowerCase(),
    orElse: () => RoundRepeatBehavior.once,
  );
}

List<Round> decodeRounds(String jsonStr) {
  final data = json.decode(jsonStr) as List<dynamic>;
  return data.map((element) => Round.fromJson(element as Map<String, dynamic>)).toList();
}
