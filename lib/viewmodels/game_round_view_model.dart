import 'package:cod/classes/player.dart';
import 'package:cod/models/round.dart';
import 'package:cod/providers/player_providers.dart';
import 'package:cod/viewmodels/round_engine.dart';
import 'package:cod/viewmodels/round_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final roundsProvider = FutureProvider<List<Round>>((ref) async {
  final json = await rootBundle.loadString('assets/data/rounds.json');
  return decodeRounds(json);
});

final roundViewModelProvider = AsyncNotifierProvider<RoundViewModel, RoundSessionState>(RoundViewModel.new);

class RoundViewModel extends AsyncNotifier<RoundSessionState> {
  RoundViewModel() : _engine = RoundEngine(logger: _logGame);

  final RoundEngine _engine;

  static void _logGame(String message) {
    debugPrint('[RoundEngine] $message');
  }

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

    baseState = _engine.withNextRound(baseState);
    return baseState;
  }

  void markCompleted() {
    final current = state.valueOrNull;
    if (current == null || current.currentRound == null) {
      return;
    }

    debugPrint('[RoundEngine] markCompleted: ${current.currentRound!.id}');
    final recorded = _engine.recordRoundPlay(current, current.currentRound!);
    state = AsyncData(
      recorded.copyWith(
        currentPlayers: const [],
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
    debugPrint('[RoundEngine] markFailed: ${round.id}');
    if (round.category.persistsUntilSuccess) {
      state = AsyncData(current.copyWith(roundOutcome: RoundOutcome.failed));
      return;
    }

    final recorded = _engine.recordRoundPlay(current, round);
    state = AsyncData(
      recorded.copyWith(
        currentPlayers: const [],
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
      debugPrint('[RoundEngine] nextRound: no active round, fetching next.');
      state = AsyncData(_engine.withNextRound(current));
      return;
    }

    if (current.roundOutcome == RoundOutcome.failed && round.category.persistsUntilSuccess) {
      var updated = current.copyWith(clearOutcome: true, currentPlayers: const []);
      updated = _engine.assignPlayers(updated, round, incrementPlayerCount: true);
      debugPrint('[RoundEngine] nextRound: retrying ${round.id} with new players.');
      state = AsyncData(updated);
      return;
    }

    final cleared = current.copyWith(clearOutcome: true, currentPlayers: const []);
    debugPrint('[RoundEngine] nextRound: moving past ${round.id}.');
    final updated = _engine.withNextRound(cleared);
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

    resetState = _engine.withNextRound(resetState);
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

    if (nextState.currentRound == null || !nextState.currentRound!.needsPlayers) {
      if (nextState.currentPlayers.isNotEmpty) {
        nextState = nextState.copyWith(currentPlayers: const []);
      }
    } else if (players.isEmpty) {
      nextState = nextState.copyWith(currentPlayers: const []);
    } else {
      final round = nextState.currentRound!;
      final hasAllRequiredPlayers =
          nextState.currentPlayers.length == round.requiredPlayerCount &&
          nextState.currentPlayers.every(players.contains);
      if (!hasAllRequiredPlayers) {
        nextState = _engine.assignPlayers(nextState, round, incrementPlayerCount: false);
      }
    }

    state = AsyncData(nextState);
  }
}
