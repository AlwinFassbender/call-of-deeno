import 'dart:collection';

import 'package:cod/classes/player.dart';
import 'package:flutter/material.dart';

class PlayerManager extends ChangeNotifier {
  PlayerManager({List<Player>? initialPlayers}) {
    _players.addAll(initialPlayers ?? _defaultPlayers);
  }

  final List<Player> _players = [];

  UnmodifiableListView<Player> get players => UnmodifiableListView(_players);

  int get activePlayerCount => _players.where((player) => player.isActive).length;

  void toggleActiveAt(int index) {
    if (index < 0 || index >= _players.length) {
      return;
    }
    final player = _players[index];
    _players[index] = player.copyWith(isActive: !player.isActive);
    notifyListeners();
  }

  void addPlayer(Player player) {
    _players.add(player);
    notifyListeners();
  }

  static final List<Player> _defaultPlayers = [
    Player(
      name: 'Ava',
      isActive: true,
      photoUrl:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=200&q=60',
    ),
    Player(
      name: 'Mason',
      isActive: true,
      photoUrl:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=60',
    ),
    Player(
      name: 'Luna',
      photoUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
    ),
    Player(
      name: 'Leo',
      photoUrl:
          'https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?auto=format&fit=crop&w=200&q=60',
    ),
    Player(
      name: 'Mia',
      photoUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
    ),
  ];
}

class PlayerScope extends InheritedNotifier<PlayerManager> {
  const PlayerScope({super.key, required PlayerManager manager, required super.child})
      : super(notifier: manager);

  static PlayerManager of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlayerScope>();
    assert(scope != null, 'No PlayerScope found in context');
    return scope!.notifier!;
  }
}
