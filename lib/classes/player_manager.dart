import 'dart:collection';
import 'dart:convert';

import 'package:cod/classes/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerManager extends ChangeNotifier {
  PlayerManager() {
    _loadDefaults();
  }

  final List<Player> _players = [];
  final AssetBundle _bundle = rootBundle;
  final String assetPath = 'assets/data/players.json';

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

  Future<void> _loadDefaults() async {
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    final iterable = decoded is List ? decoded : (decoded is Map<String, dynamic> ? decoded['players'] : null);
    if (iterable is List) {
      final defaults = iterable.whereType<Map<String, dynamic>>().map(Player.fromJson).toList(growable: false);
      if (defaults.isNotEmpty) {
        _players
          ..clear()
          ..addAll(defaults);
        notifyListeners();
        return;
      }
    }
  }
}
