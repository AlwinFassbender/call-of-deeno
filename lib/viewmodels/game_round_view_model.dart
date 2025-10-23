import 'dart:math';

import 'package:cod/classes/player.dart';
import 'package:cod/models/round.dart';
import 'package:cod/providers/player_providers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final roundsProvider = FutureProvider<List<Round>>((ref) async {
  final json = await rootBundle.loadString('assets/data/rounds.json');
  return decodeRounds(json);
});

enum RoundOutcome { completed, failed }

class RoundSessionState {
  const RoundSessionState({
    required this.rounds,
    required this.completedRoundIds,
    required this.categoryCompletionCounts,
    required this.playerSelectionCounts,
    required this.availablePlayers,
    required this.currentPlayers,
    this.currentRound,
    this.roundOutcome,
  });

  factory RoundSessionState.initial({required List<Round> rounds, required List<Player> players}) {
    final categoryCounts = <RoundCategory, int>{for (final round in rounds) round.category: 0};
    final playerCounts = <String, int>{for (final player in players) player.name: 0};
    return RoundSessionState(
      rounds: rounds,
      completedRoundIds: <String>{},
      categoryCompletionCounts: categoryCounts,
      playerSelectionCounts: playerCounts,
      availablePlayers: players,
      currentPlayers: const [],
    );
  }

  final List<Round> rounds;
  final Set<String> completedRoundIds;
  final Map<RoundCategory, int> categoryCompletionCounts;
  final Map<String, int> playerSelectionCounts;
  final List<Player> availablePlayers;
  final Round? currentRound;
  final List<Player> currentPlayers;
  final RoundOutcome? roundOutcome;

  bool get showRewardCard => roundOutcome == RoundOutcome.completed && currentRound?.rewardDescription != null;

  bool get showPunishmentCard => roundOutcome == RoundOutcome.failed && currentRound?.punishmentDescription != null;

  bool get showNeutralContinue =>
      roundOutcome != null && currentRound?.rewardDescription == null && currentRound?.punishmentDescription == null;

  bool get hasRoundsRemaining => completedRoundIds.length < rounds.length;

  RoundSessionState copyWith({
    List<Round>? rounds,
    Set<String>? completedRoundIds,
    Map<RoundCategory, int>? categoryCompletionCounts,
    Map<String, int>? playerSelectionCounts,
    List<Player>? availablePlayers,
    Round? currentRound,
    bool setCurrentRound = false,
    List<Player>? currentPlayers,
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
      roundOutcome: clearOutcome ? null : (roundOutcome ?? this.roundOutcome),
    );
  }
}

final roundViewModelProvider = AsyncNotifierProvider<RoundViewModel, RoundSessionState>(RoundViewModel.new);

class RoundViewModel extends AsyncNotifier<RoundSessionState> {
  RoundViewModel() : _random = Random();

  final Random _random;

  @override
  Future<RoundSessionState> build() async {
    final rounds = await ref.watch(roundsProvider.future);
    final players = ref.read(activePlayersProvider);

    ref.listen<List<Player>>(activePlayersProvider, (previous, next) {
      _syncPlayers(next);
    });

    var baseState = RoundSessionState.initial(rounds: rounds, players: players);
    if (players.isEmpty || rounds.isEmpty) {
      return baseState;
    }

    baseState = _withNextRound(baseState, ignoreCompleted: false);
    return baseState;
  }

  void markCompleted() {
    final current = state.valueOrNull;
    if (current == null || current.currentRound == null) {
      return;
    }

    final round = current.currentRound!;

    final completedIds = {...current.completedRoundIds}..add(round.id);
    final categoryCounts = {...current.categoryCompletionCounts};
    categoryCounts[round.category] = (categoryCounts[round.category] ?? 0) + 1;

    state = AsyncData(
      current.copyWith(
        completedRoundIds: completedIds,
        categoryCompletionCounts: categoryCounts,
        roundOutcome: RoundOutcome.completed,
      ),
    );
  }

  void markFailed() {
    final current = state.valueOrNull;
    if (current == null || current.currentRound == null) {
      return;
    }

    final round = current.currentRound!;
    final completedIds = {...current.completedRoundIds};
    final categoryCounts = {...current.categoryCompletionCounts};

    if (!round.category.persistsUntilSuccess) {
      completedIds.add(round.id);
      categoryCounts[round.category] = (categoryCounts[round.category] ?? 0) + 1;
    }

    state = AsyncData(
      current.copyWith(
        completedRoundIds: completedIds,
        categoryCompletionCounts: categoryCounts,
        roundOutcome: RoundOutcome.failed,
      ),
    );
  }

  void nextRound() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final round = current.currentRound;
    if (round == null) {
      state = AsyncData(_withNextRound(current, ignoreCompleted: false));
      return;
    }

    if (current.roundOutcome == RoundOutcome.failed && round.category.persistsUntilSuccess) {
      var updated = current.copyWith(clearOutcome: true, currentPlayers: const []);
      updated = _assignPlayers(updated, round, incrementPlayerCount: true);
      state = AsyncData(updated);
      return;
    }

    final updated = _withNextRound(current.copyWith(clearOutcome: true), ignoreCompleted: false);
    state = AsyncData(updated);
  }

  void resetRounds() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    var resetState = RoundSessionState.initial(rounds: current.rounds, players: current.availablePlayers);

    if (resetState.rounds.isEmpty || resetState.availablePlayers.isEmpty) {
      state = AsyncData(resetState);
      return;
    }

    resetState = _withNextRound(resetState, ignoreCompleted: false);
    state = AsyncData(resetState);
  }

  void _syncPlayers(List<Player> players) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final counts = <String, int>{
      for (final entry in current.playerSelectionCounts.entries)
        if (players.any((player) => player.name == entry.key)) entry.key: entry.value,
    };

    for (final player in players) {
      counts.putIfAbsent(player.name, () => 0);
    }

    var nextState = current.copyWith(availablePlayers: players, playerSelectionCounts: counts);

    if (nextState.currentRound == null || !nextState.currentRound!.needsPlayers) {
      if (nextState.currentPlayers.isNotEmpty) {
        nextState = nextState.copyWith(currentPlayers: const []);
      }
    } else if (players.isEmpty) {
      nextState = nextState.copyWith(currentPlayers: const []);
    } else {
      final round = nextState.currentRound!;
      final hasAllPlayers =
          nextState.currentPlayers.length == round.requiredPlayerCount &&
          nextState.currentPlayers.every(players.contains);
      if (!hasAllPlayers) {
        nextState = _assignPlayers(nextState, round, incrementPlayerCount: false);
      }
    }

    state = AsyncData(nextState);
  }

  RoundSessionState _withNextRound(RoundSessionState state, {required bool ignoreCompleted}) {
    if (state.rounds.isEmpty) {
      return state;
    }

    final nextRound = _pickRound(state, ignoreCompleted: ignoreCompleted);
    if (nextRound == null) {
      return state.copyWith(currentRound: null, setCurrentRound: true, currentPlayers: const []);
    }

    var updatedState = state.copyWith(currentRound: nextRound, setCurrentRound: true, currentPlayers: const []);

    if (nextRound.needsPlayers && state.availablePlayers.isNotEmpty) {
      updatedState = _assignPlayers(updatedState, nextRound, incrementPlayerCount: true);
    }

    return updatedState;
  }

  Round? _pickRound(RoundSessionState state, {required bool ignoreCompleted}) {
    final available = state.rounds.where((round) {
      if (ignoreCompleted) {
        return true;
      }
      return !state.completedRoundIds.contains(round.id);
    }).toList();

    if (available.isEmpty) {
      return null;
    }

    final categoryCounts = state.categoryCompletionCounts;
    final minUsage = available.map((round) => categoryCounts[round.category] ?? 0).reduce(min);

    final candidates = available.where((round) => (categoryCounts[round.category] ?? 0) == minUsage).toList();

    return candidates[_random.nextInt(candidates.length)];
  }

  RoundSessionState _assignPlayers(RoundSessionState state, Round round, {required bool incrementPlayerCount}) {
    final available = state.availablePlayers;
    if (available.isEmpty || !round.needsPlayers) {
      return state.copyWith(currentPlayers: const []);
    }

    final requiredCount = round.requiredPlayerCount;
    final selected = <Player>[];
    final usedNames = <String>{};

    if (round.playerIds.isNotEmpty) {
      for (final id in round.playerIds) {
        if (selected.length >= requiredCount) {
          break;
        }
        final match = _findPlayerByName(available, id);
        if (match != null && usedNames.add(match.name)) {
          selected.add(match);
        }
      }
    }

    while (selected.length < requiredCount) {
      final candidate = _chooseLeastSelectedPlayer(state, exclude: usedNames);
      if (candidate == null) {
        break;
      }
      usedNames.add(candidate.name);
      selected.add(candidate);
    }

    final counts = {...state.playerSelectionCounts};
    if (incrementPlayerCount) {
      for (final player in selected) {
        counts[player.name] = (counts[player.name] ?? 0) + 1;
      }
    }

    return state.copyWith(currentPlayers: selected, playerSelectionCounts: counts);
  }

  Player? _chooseLeastSelectedPlayer(RoundSessionState state, {Set<String>? exclude}) {
    final excluded = exclude ?? <String>{};
    final players = state.availablePlayers.where((player) => !excluded.contains(player.name)).toList(growable: false);
    if (players.isEmpty) {
      return null;
    }
    final counts = state.playerSelectionCounts;
    final minUsage = players.map((player) => counts[player.name] ?? 0).reduce(min);
    final candidates = players.where((player) => (counts[player.name] ?? 0) == minUsage).toList();
    return candidates[_random.nextInt(candidates.length)];
  }

  Player? _findPlayerByName(List<Player> players, String id) {
    final target = id.toLowerCase();
    for (final player in players) {
      if (player.name.toLowerCase() == target) {
        return player;
      }
    }
    return null;
  }
}
