import 'package:cod/classes/player.dart';
import 'package:cod/classes/player_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final playerManagerProvider = ChangeNotifierProvider<PlayerManager>((ref) {
  final manager = PlayerManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final activePlayersProvider = Provider<List<Player>>((ref) {
  final manager = ref.watch(playerManagerProvider);
  return manager.players.where((player) => player.isActive).toList(growable: false);
});
