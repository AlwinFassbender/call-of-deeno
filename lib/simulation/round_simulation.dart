import 'dart:math';

import 'package:cod/classes/player.dart';
import 'package:cod/models/round.dart';
import 'package:cod/viewmodels/round_engine.dart';
import 'package:cod/viewmodels/round_state.dart';
import 'package:flutter/foundation.dart';

class RoundSimulationEntry {
  const RoundSimulationEntry({
    required this.category,
    required this.playerNames,
    required this.isRepeatable,
    this.title,
    this.description,
  });

  final String category;
  final List<String> playerNames;
  final bool isRepeatable;
  final String? title;
  final String? description;
}

List<RoundSimulationEntry> simulateRounds({required List<Round> rounds, required List<Player> players, int? seed}) {
  if (rounds.isEmpty || players.isEmpty) {
    return const [];
  }

  final engine = RoundEngine(
    random: Random(seed ?? DateTime.now().millisecondsSinceEpoch),
    logger: (message) => debugPrint('[RoundSim] $message'),
  );
  var state = RoundSessionState.initial(rounds: rounds, players: players);
  state = engine.withNextRound(state);

  final entries = <RoundSimulationEntry>[];
  while (state.currentRound != null) {
    final round = state.currentRound!;
    final playerNames = state.currentPlayers.map((player) => player.name).toList(growable: false);
    final isRepeatable = round.repeatBehavior != RoundRepeatBehavior.once;

    debugPrint('[RoundSim] draw #${entries.length + 1}: ${round.id} -> ${playerNames.join(', ')}');

    entries.add(
      RoundSimulationEntry(
        category: round.category.label,
        playerNames: playerNames,
        isRepeatable: isRepeatable,
        title: isRepeatable ? round.title : null,
        description: isRepeatable ? round.taskDescription : null,
      ),
    );

    final recorded = engine.recordRoundPlay(state, round).copyWith(currentPlayers: const []);
    state = engine.withNextRound(recorded);

    if (state.currentRound == null) {
      debugPrint('[RoundSim] simulation complete after ${entries.length} draws.');
      break;
    }
  }

  return entries;
}
