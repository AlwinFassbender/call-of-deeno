import 'dart:math';

import 'package:cod/classes/player.dart';
import 'package:cod/models/round.dart';
import 'package:cod/viewmodels/round_state.dart';

class RoundEngine {
  RoundEngine({Random? random, void Function(String message)? logger})
      : _random = random ?? Random(),
        _logger = logger;

  final Random _random;
  final void Function(String message)? _logger;

  void _log(String message) {
    _logger?.call(message);
  }

  RoundSessionState withNextRound(RoundSessionState state) {
    if (state.rounds.isEmpty) {
      return state;
    }

    final nextRound = _pickRound(state);
    if (nextRound == null) {
      return state.copyWith(
        currentRound: null,
        setCurrentRound: true,
        currentPlayers: const [],
      );
    }

    _log('next-round: ${nextRound.id} (${nextRound.category.name}, ${nextRound.repeatBehavior.name})');

    var updatedState = state.copyWith(
      currentRound: nextRound,
      setCurrentRound: true,
      currentPlayers: const [],
    );

    _log('withNextRound: selected ${nextRound.id} (${nextRound.category.name}), repeat=${nextRound.repeatBehavior.name}.');

    if (nextRound.needsPlayers) {
      updatedState = assignPlayers(updatedState, nextRound, incrementPlayerCount: true);
    }

    return updatedState;
  }

  RoundSessionState assignPlayers(
    RoundSessionState state,
    Round round, {
    required bool incrementPlayerCount,
  }) {
    final available = state.availablePlayers;
    if (!round.needsPlayers || available.isEmpty) {
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

    return state.copyWith(
      currentPlayers: selected,
      playerSelectionCounts: counts,
    );
  }

  RoundSessionState recordRoundPlay(RoundSessionState state, Round round) {
    final playCounts = {...state.roundPlayCounts};
    final newCount = (playCounts[round.id] ?? 0) + 1;
    playCounts[round.id] = newCount;

    final categoryCounts = {...state.categoryCompletionCounts};
    categoryCounts[round.category] = (categoryCounts[round.category] ?? 0) + 1;

    final completed = {...state.completedRoundIds};
    if (round.isFinite && round.isExhausted(newCount)) {
      completed.add(round.id);
    }

    final recent = [...state.recentCategories, round.category];
    if (recent.length > 4) {
      recent.removeAt(0);
    }

    final servedOrder = state.totalRoundsServed + 1;
    final lastServed = {...state.roundLastServedOrder}..[round.id] = servedOrder;

    final finiteCompleted = round.isFinite ? state.finitePlaysCompleted + 1 : state.finitePlaysCompleted;

    _log('record: ${round.id} played $newCount× (category ${round.category.name})');

    return state.copyWith(
      roundPlayCounts: playCounts,
      categoryCompletionCounts: categoryCounts,
      completedRoundIds: completed,
      recentCategories: recent,
      totalRoundsServed: servedOrder,
      roundLastServedOrder: lastServed,
      finitePlaysCompleted: finiteCompleted,
    );
  }

  Round? _pickRound(RoundSessionState state) {
    final remainingFiniteRaw = state.finiteTargetPlays - state.finitePlaysCompleted;
    final remainingFinite = remainingFiniteRaw <= 0 ? 1.0 : remainingFiniteRaw;
    final now = state.totalRoundsServed.toDouble();

    final weights = <Round, double>{};
    double totalWeight = 0;

    double totalFiniteQuota = 0;
    for (final round in state.rounds) {
      if (round.repeatBehavior == RoundRepeatBehavior.repeatUnlimited) {
        continue;
      }
      final plays = state.roundPlayCounts[round.id] ?? 0;
      final remainingQuota = round.effectiveMaxRepeats - plays;
      if (remainingQuota > 0) {
        totalFiniteQuota += remainingQuota;
      }
    }
    if (totalFiniteQuota <= 0) {
      totalFiniteQuota = 1;
    }

    for (final round in state.rounds) {
      final plays = state.roundPlayCounts[round.id] ?? 0;

      if (round.repeatBehavior == RoundRepeatBehavior.repeatUnlimited) {
        final defaultLast = -(round.cooldownRounds ?? 5);
        final lastServed = (state.roundLastServedOrder[round.id] ?? defaultLast).toDouble();
        final sinceLastRaw = now - lastServed;
        final sinceLast = sinceLastRaw < 0 ? 0.0 : sinceLastRaw;
        final cooldown = (round.cooldownRounds ?? 5).toDouble();
        if (sinceLast < cooldown) {
          continue;
        }

        var weight = 0.35 * ((sinceLast - cooldown) / (cooldown + 1) + 1);
        weight = weight < 0 ? 0.01 : weight;
        weight *= 0.75 + _random.nextDouble() * 0.3;

        weights[round] = weight;
        totalWeight += weight;
        continue;
      }

      final remainingQuota = round.effectiveMaxRepeats - plays;
      if (remainingQuota <= 0) {
        continue;
      }

      final defaultLast = -1.0;
      final lastServed = (state.roundLastServedOrder[round.id] ?? defaultLast).toDouble();
      final sinceLastRaw = now - lastServed;
      final sinceLast = sinceLastRaw < 0 ? 0.0 : sinceLastRaw;

      final idealSpacingRaw = remainingFinite / remainingQuota;
      final idealSpacing = idealSpacingRaw < 1 ? 1.0 : idealSpacingRaw;
      var weight = remainingQuota * (1 + sinceLast / (idealSpacing * 0.7));
      weight *= 0.85 + _random.nextDouble() * 0.3;

      weights[round] = weight;
      totalWeight += weight;
    }

    if (totalWeight <= 0) {
      _log('pick-round: no eligible candidates.');
      return null;
    }

    var target = _random.nextDouble() * totalWeight;
    for (final entry in weights.entries) {
      target -= entry.value;
      if (target <= 0) {
        _log('pick-round: ${entry.key.id} weight=${entry.value.toStringAsFixed(2)} total=${totalWeight.toStringAsFixed(2)}');
        return entry.key;
      }
    }

    final fallback = weights.entries.last;
    _log('pick-round fallback: ${fallback.key.id}');
    return fallback.key;
  }

  double _recencyPenalty(RoundSessionState state, Round round) {
    if (state.recentCategories.isEmpty) {
      return 0;
    }

    double penalty = 0;
    final history = state.recentCategories;
    for (var i = 0; i < history.length; i++) {
      final category = history[history.length - 1 - i];
      if (category == round.category) {
        penalty = switch (i) {
          0 => 0.6,
          1 => 0.35,
          2 => 0.2,
          _ => 0.1,
        };
        break;
      }
    }
    return penalty;
  }

  Player? _chooseLeastSelectedPlayer(RoundSessionState state, {Set<String>? exclude}) {
    final excluded = exclude ?? <String>{};
    final players = state.availablePlayers.where((player) => !excluded.contains(player.name)).toList(growable: false);
    if (players.isEmpty) {
      return null;
    }

    final counts = state.playerSelectionCounts;
    final minUsage = players.map((player) => counts[player.name] ?? 0).reduce(min);
    final candidates = players.where((player) => (counts[player.name] ?? 0) == minUsage).toList(growable: false);
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
