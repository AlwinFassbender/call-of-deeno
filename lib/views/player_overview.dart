import 'package:cod/classes/player.dart';
import 'package:cod/theme/colors.dart';
import 'package:cod/views/add_player.dart';
import 'package:cod/views/game_round.dart';
import 'package:cod/providers/player_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerOverviewScreen extends ConsumerWidget {
  const PlayerOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(playerManagerProvider);
    final players = manager.players;
    final activeCount = manager.activePlayerCount;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Players', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: players.length + 1,
                  itemBuilder: (context, index) {
                    if (index == players.length) {
                      return _AddPlayerCard(onTap: () => Navigator.of(context).pushNamed(AddPlayerScreen.routeName));
                    }
                    final player = players[index];
                    return _PlayerCard(
                      player: player,
                      onTap: () => ref.read(playerManagerProvider).toggleActiveAt(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ElevatedButton(
            onPressed: activeCount >= 2 ? () => Navigator.of(context).pushNamed(GameRoundScreen.routeName) : null,
            child: Text(activeCount >= 2 ? 'Start Game' : 'Select at least 2 players'),
          ),
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = player.isActive ? AppColors.primary : AppColors.surfaceBorder;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: player.isActive ? 2 : 1),
          boxShadow: player.isActive
              ? const [BoxShadow(color: Color(0x33FF5D68), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final radius = box.biggest.shortestSide / 2;
                  return CircleAvatar(radius: radius, backgroundImage: _playerImage(player));
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(player.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  ImageProvider _playerImage(Player player) {
    if (player.photoBytes != null && player.photoBytes!.isNotEmpty) {
      return MemoryImage(player.photoBytes!);
    }
    final asset = player.photoAsset ?? Player.defaultAvatarAsset;
    return AssetImage(asset);
  }
}

class _AddPlayerCard extends StatelessWidget {
  const _AddPlayerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1_outlined, size: 32, color: Colors.white54),
            SizedBox(height: 10),
            Text(
              'Add\nPlayer',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
