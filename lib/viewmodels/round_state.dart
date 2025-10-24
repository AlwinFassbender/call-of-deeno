import 'package:cod/classes/player.dart';
import 'package:cod/models/round.dart';

enum RoundOutcome { completed, failed }

class RoundSessionState {
  const RoundSessionState({
    required this.rounds,
    required this.completedRoundIds,
    required this.categoryCompletionCounts,
    required this.playerSelectionCounts,
    required this.availablePlayers,
    required this.currentPlayers,
    required this.roundPlayCounts,
    required this.categoryTargetWeights,
    required this.finiteTargetPlays,
    required this.finitePlaysCompleted,
    required this.recentCategories,
    required this.totalRoundsServed,
    required this.roundLastServedOrder,
    this.currentRound,
    this.roundOutcome,
  });

  factory RoundSessionState.initial({required List<Round> rounds, required List<Player> players}) {
    final categoryCounts = <RoundCategory, int>{for (final round in rounds) round.category: 0};
    final playerCounts = <String, int>{for (final player in players) player.name: 0};
    final playCounts = <String, int>{for (final round in rounds) round.id: 0};
    final lastServed = <String, int>{for (final round in rounds) round.id: -1000};

    final categoryWeights = <RoundCategory, double>{};
    double finiteQuota = 0;
    for (final round in rounds) {
      categoryWeights[round.category] = (categoryWeights[round.category] ?? 0) + round.targetPlayWeight;
      if (round.isFinite) {
        finiteQuota += round.finitePlayQuota;
      }
    }

    return RoundSessionState(
      rounds: rounds,
      completedRoundIds: <String>{},
      categoryCompletionCounts: categoryCounts,
      playerSelectionCounts: playerCounts,
      availablePlayers: players,
      currentPlayers: const [],
      roundPlayCounts: playCounts,
      categoryTargetWeights: categoryWeights,
      finiteTargetPlays: finiteQuota,
      finitePlaysCompleted: 0,
      recentCategories: const [],
      totalRoundsServed: 0,
      roundLastServedOrder: lastServed,
    );
  }

  final List<Round> rounds;
  final Set<String> completedRoundIds;
  final Map<RoundCategory, int> categoryCompletionCounts;
  final Map<String, int> playerSelectionCounts;
  final List<Player> availablePlayers;
  final Round? currentRound;
  final List<Player> currentPlayers;
  final Map<String, int> roundPlayCounts;
  final Map<RoundCategory, double> categoryTargetWeights;
  final double finiteTargetPlays;
  final double finitePlaysCompleted;
  final List<RoundCategory> recentCategories;
  final int totalRoundsServed;
  final Map<String, int> roundLastServedOrder;
  final RoundOutcome? roundOutcome;

  bool get showRewardCard => roundOutcome == RoundOutcome.completed && currentRound?.rewardDescription != null;

  bool get showPunishmentCard => roundOutcome == RoundOutcome.failed && currentRound?.punishmentDescription != null;

  bool get showNeutralContinue =>
      roundOutcome != null && currentRound?.rewardDescription == null && currentRound?.punishmentDescription == null;

  double get finiteProgress => finiteTargetPlays <= 0 ? 1 : finitePlaysCompleted / finiteTargetPlays;

  bool get hasFiniteRoundsRemaining =>
      rounds.any((round) => round.isFinite && !round.isExhausted(roundPlayCounts[round.id] ?? 0));

  RoundSessionState copyWith({
    List<Round>? rounds,
    Set<String>? completedRoundIds,
    Map<RoundCategory, int>? categoryCompletionCounts,
    Map<String, int>? playerSelectionCounts,
    List<Player>? availablePlayers,
    Round? currentRound,
    bool setCurrentRound = false,
    List<Player>? currentPlayers,
    Map<String, int>? roundPlayCounts,
    Map<RoundCategory, double>? categoryTargetWeights,
    double? finiteTargetPlays,
    double? finitePlaysCompleted,
    List<RoundCategory>? recentCategories,
    int? totalRoundsServed,
    Map<String, int>? roundLastServedOrder,
    RoundOutcome? roundOutcome,
    bool clearOutcome = false,
  }) {
    return RoundSessionState(
      rounds: rounds ?? this.rounds,
      completedRoundIds: completedRoundIds ?? this.completedRoundIds,
      categoryCompletionCounts: categoryCompletionCounts ?? this.categoryCompletionCounts,
      playerSelectionCounts: playerSelectionCounts ?? this.playerSelectionCounts,
      availablePlayers: availablePlayers ?? this.availablePlayers,
      currentRound: setCurrentRound ? currentRound : this.currentRound,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      roundPlayCounts: roundPlayCounts ?? this.roundPlayCounts,
      categoryTargetWeights: categoryTargetWeights ?? this.categoryTargetWeights,
      finiteTargetPlays: finiteTargetPlays ?? this.finiteTargetPlays,
      finitePlaysCompleted: finitePlaysCompleted ?? this.finitePlaysCompleted,
      recentCategories: recentCategories ?? this.recentCategories,
      totalRoundsServed: totalRoundsServed ?? this.totalRoundsServed,
      roundLastServedOrder: roundLastServedOrder ?? this.roundLastServedOrder,
      roundOutcome: clearOutcome ? null : (roundOutcome ?? this.roundOutcome),
    );
  }

  double categoryTargetWeight(RoundCategory category) {
    final weight = categoryTargetWeights[category] ?? 1;
    return weight <= 0 ? 1 : weight;
  }

  int playCountFor(Round round) => roundPlayCounts[round.id] ?? 0;
}
