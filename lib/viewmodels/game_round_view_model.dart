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
    this.currentRound,
    this.currentPlayer,
    this.roundOutcome,
  });

  factory RoundSessionState.initial({
    required List<Round> rounds,
    required List<Player> players,
  }) {
    final categoryCounts = <RoundCategory, int>{
      for (final round in rounds) round.category: 0,
    };
    final playerCounts = <String, int>{
      for (final player in players) player.name: 0,
    };
    return RoundSessionState(
      rounds: rounds,
      completedRoundIds: <String>{},
      categoryCompletionCounts: categoryCounts,
      playerSelectionCounts: playerCounts,
      availablePlayers: players,
    );
  }

  final List<Round> rounds;
  final Set<String> completedRoundIds;
  final Map<RoundCategory, int> categoryCompletionCounts;
  final Map<String, int> playerSelectionCounts;
  final List<Player> availablePlayers;
  final Round? currentRound;
  final Player? currentPlayer;
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
    Player? currentPlayer,
    bool setCurrentPlayer = false,
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
      currentPlayer: setCurrentPlayer ? currentPlayer : this.currentPlayer,
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
      final updated = _assignPlayer(current.copyWith(clearOutcome: true), round, incrementPlayerCount: true);
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

    var resetState = RoundSessionState.initial(
      rounds: current.rounds,
      players: current.availablePlayers,
    );

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

    var nextState = current.copyWith(
      availablePlayers: players,
      playerSelectionCounts: counts,
    );

    if (players.isEmpty) {
      nextState = nextState.copyWith(currentPlayer: null, setCurrentPlayer: true);
    } else if (nextState.currentPlayer == null || !players.contains(nextState.currentPlayer)) {
      if (nextState.currentRound != null) {
        nextState = _assignPlayer(nextState, nextState.currentRound!, incrementPlayerCount: false);
      }
    }

    state = AsyncData(nextState);
  }

  RoundSessionState _withNextRound(RoundSessionState state, {required bool ignoreCompleted}) {
    if (state.rounds.isEmpty) {
      return state;
    }

    final availablePlayers = state.availablePlayers;
    if (availablePlayers.isEmpty) {
      return state.copyWith(
        currentRound: null,
        setCurrentRound: true,
        currentPlayer: null,
        setCurrentPlayer: true,
      );
    }

    final nextRound = _pickRound(state, ignoreCompleted: ignoreCompleted);
    if (nextRound == null) {
      return state.copyWith(
        currentRound: null,
        setCurrentRound: true,
        currentPlayer: null,
        setCurrentPlayer: true,
      );
    }

    final updatedState = _assignPlayer(
      state.copyWith(currentRound: nextRound, setCurrentRound: true),
      nextRound,
      incrementPlayerCount: true,
    );
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
    final minUsage = available
        .map((round) => categoryCounts[round.category] ?? 0)
        .reduce(min);

    final candidates = available
        .where((round) => (categoryCounts[round.category] ?? 0) == minUsage)
        .toList();

    return candidates[_random.nextInt(candidates.length)];
  }

  RoundSessionState _assignPlayer(
    RoundSessionState state,
    Round round, {
    required bool incrementPlayerCount,
  }) {
    if (state.availablePlayers.isEmpty) {
      return state.copyWith(currentPlayer: null, setCurrentPlayer: true);
    }

    Player chosen;
    if (round.playerId != null) {
      final match = state.availablePlayers.firstWhere(
        (player) => player.name.toLowerCase() == round.playerId!.toLowerCase(),
        orElse: () => _chooseLeastSelectedPlayer(state),
      );
      chosen = match;
    } else {
      chosen = _chooseLeastSelectedPlayer(state);
    }

    final counts = {...state.playerSelectionCounts};
    if (incrementPlayerCount) {
      counts[chosen.name] = (counts[chosen.name] ?? 0) + 1;
    }

    return state.copyWith(
      currentPlayer: chosen,
      setCurrentPlayer: true,
      playerSelectionCounts: counts,
    );
  }

  Player _chooseLeastSelectedPlayer(RoundSessionState state) {
    final players = state.availablePlayers;
    if (players.isEmpty) {
      throw StateError('No players available');
    }
    final counts = state.playerSelectionCounts;
    final minUsage = players
        .map((player) => counts[player.name] ?? 0)
        .reduce(min);
    final candidates = players
        .where((player) => (counts[player.name] ?? 0) == minUsage)
        .toList();
    return candidates[_random.nextInt(candidates.length)];
  }
}
