import 'package:cod/classes/player.dart';
import 'package:cod/models/round.dart';
import 'package:cod/theme/colors.dart';
import 'package:cod/viewmodels/game_round_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class GameRoundScreen extends ConsumerStatefulWidget {
  const GameRoundScreen({super.key});

  static const routeName = '/game-round';

  @override
  ConsumerState<GameRoundScreen> createState() => _GameRoundScreenState();
}

class _GameRoundScreenState extends ConsumerState<GameRoundScreen> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(roundViewModelProvider);
    final notifier = ref.read(roundViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorPlaceholder(onRetry: () => ref.refresh(roundViewModelProvider.future)),
          data: (state) => _RoundBody(state: state, notifier: notifier),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: asyncState.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
          data: (state) => _RoundActionBar(state: state, notifier: notifier),
        ),
      ),
    );
  }
}

class _RoundBody extends StatelessWidget {
  const _RoundBody({required this.state, required this.notifier});

  final RoundSessionState state;
  final RoundViewModel notifier;

  @override
  Widget build(BuildContext context) {
    final round = state.currentRound;
    final player = state.currentPlayer;

    if (state.availablePlayers.isEmpty) {
      return _CenteredMessage(
        title: 'No active players',
        subtitle: 'Select at least one active player to start a round.',
        primaryAction: _MessageAction(label: 'Back to Players', onTap: () => Navigator.of(context).pop()),
      );
    }

    if (round == null || player == null) {
      return _CenteredMessage(
        title: 'All rounds completed',
        subtitle: 'You have played through every available round.',
        primaryAction: _MessageAction(label: 'Play Again', onTap: notifier.resetRounds),
      );
    }

    final completedCount = state.completedRoundIds.length;
    final outcomeCountsAsCompleted =
        state.roundOutcome == RoundOutcome.completed ||
        (state.roundOutcome == RoundOutcome.failed && !round.category.persistsUntilSuccess);
    final displayNumber = outcomeCountsAsCompleted ? completedCount : completedCount + 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'Round $displayNumber',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _PlayerChip(player: player),
              const Spacer(),
              _CategoryBadge(category: round.category),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.05, 0.04),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: offsetAnimation, child: child),
                );
              },
              child: _RoundCard(
                key: ValueKey('${round.id}-${state.roundOutcome?.name ?? 'task'}'),
                child: state.roundOutcome == null
                    ? _TaskContent(round: round)
                    : _ResultContent(round: round, outcome: state.roundOutcome!),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RoundActionBar extends StatelessWidget {
  const _RoundActionBar({required this.state, required this.notifier});

  final RoundSessionState state;
  final RoundViewModel notifier;

  @override
  Widget build(BuildContext context) {
    final round = state.currentRound;
    if (round == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ElevatedButton(onPressed: notifier.resetRounds, child: const Text('Restart Rounds')),
      );
    }

    if (state.roundOutcome == null) {
      final hasReward = round.rewardDescription != null;
      final hasPunishment = round.punishmentDescription != null;

      if (!hasReward && !hasPunishment) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ElevatedButton(
            onPressed: () {
              notifier.markCompleted();
              notifier.nextRound();
            },
            child: const Text('Next Round'),
          ),
        );
      }

      final buttons = <Widget>[];
      if (hasReward) {
        buttons.add(
          Expanded(
            child: _ResultChoiceButton(
              label: 'Completed',
              icon: Icons.check_circle_outline,
              backgroundColor: const Color(0xFF0A2E27),
              foregroundColor: const Color(0xFF4EE08C),
              onTap: notifier.markCompleted,
            ),
          ),
        );
      }
      if (hasReward && hasPunishment) {
        buttons.add(const SizedBox(width: 16));
      }
      if (hasPunishment) {
        buttons.add(
          Expanded(
            child: _ResultChoiceButton(
              label: 'Failed',
              icon: Icons.cancel_outlined,
              backgroundColor: const Color(0xFF331820),
              foregroundColor: const Color(0xFFFF6C7A),
              onTap: notifier.markFailed,
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Row(children: buttons),
      );
    }

    final label = (state.roundOutcome == RoundOutcome.failed && round.category.persistsUntilSuccess)
        ? 'Next Player'
        : 'Next Round';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ElevatedButton(onPressed: notifier.nextRound, child: Text(label)),
    );
  }
}

class _TaskContent extends StatelessWidget {
  const _TaskContent({required this.round});

  final Round round;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(round.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
          const SizedBox(height: 12),
          Text(round.taskDescription, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
          const SizedBox(height: 16),
          if (round.taskVideoPath != null || round.taskPhotoPath != null)
            _RoundMedia(videoPath: round.taskVideoPath, photoPath: round.taskPhotoPath),
        ],
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.round, required this.outcome});

  final Round round;
  final RoundOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final isSuccess = outcome == RoundOutcome.completed;
    final heading = isSuccess ? 'Reward' : 'Punishment';
    final description = isSuccess ? round.rewardDescription : round.punishmentDescription;
    final videoPath = isSuccess ? round.rewardVideoPath : round.taskVideoPath;
    final photoPath = isSuccess ? round.rewardPhotoPath : round.taskPhotoPath;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFF153D2A) : const Color(0xFF3A1D26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isSuccess ? 'Completed' : 'Failed',
              style: TextStyle(
                color: isSuccess ? const Color(0xFF52E39E) : const Color(0xFFFF6C7A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(heading, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
          ],
          const SizedBox(height: 16),
          if (videoPath != null || photoPath != null) _RoundMedia(videoPath: videoPath, photoPath: photoPath),
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: child,
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 18, backgroundImage: _playerImage(player)),
        const SizedBox(width: 12),
        Text('${player.name}\'s turn', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }

  ImageProvider _playerImage(Player player) {
    if (player.photoBytes != null && player.photoBytes!.isNotEmpty) {
      return MemoryImage(player.photoBytes!);
    }
    if (player.photoAsset != null && player.photoAsset!.isNotEmpty) {
      return AssetImage(player.photoAsset!);
    }
    return const AssetImage(Player.defaultAvatarAsset);
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final RoundCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(category.label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ResultChoiceButton extends StatelessWidget {
  const _ResultChoiceButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: foregroundColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundMedia extends StatefulWidget {
  const _RoundMedia({this.videoPath, this.photoPath});

  final String? videoPath;
  final String? photoPath;

  @override
  State<_RoundMedia> createState() => _RoundMediaState();
}

class _RoundMediaState extends State<_RoundMedia> {
  VideoPlayerController? _controller;
  Future<void>? _initialiseController;

  @override
  void initState() {
    super.initState();
    _prepareController();
  }

  @override
  void didUpdateWidget(covariant _RoundMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _disposeController();
      _prepareController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _prepareController() {
    if (widget.videoPath == null) {
      return;
    }
    final controller = VideoPlayerController.asset(widget.videoPath!);
    _controller = controller;
    _initialiseController = controller
        .initialize()
        .then((_) {
          controller
            ..setLooping(true)
            ..setVolume(0)
            ..play();
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((_) {
          // Ignore loading errors; a fallback image will be shown instead.
        });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialiseController = null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(aspectRatio: 16 / 9, child: _buildMediaContent(context)),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    if (_controller != null) {
      return FutureBuilder<void>(
        future: _initialiseController,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _MediaPlaceholder(icon: Icons.videocam);
          }
          if (snapshot.hasError) {
            return const _MediaPlaceholder(icon: Icons.videocam_off);
          }
          return VideoPlayer(_controller!);
        },
      );
    }

    if (widget.photoPath != null) {
      return Image.asset(
        widget.photoPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _MediaPlaceholder(icon: Icons.image_not_supported),
      );
    }

    return const _MediaPlaceholder(icon: Icons.image_outlined);
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceElevated,
      child: Icon(icon, color: Colors.white24, size: 42),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.title, required this.subtitle, this.primaryAction});

  final String title;
  final String subtitle;
  final _MessageAction? primaryAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (primaryAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: primaryAction!.onTap, child: Text(primaryAction!.label)),
          ],
        ],
      ),
    );
  }
}

class _MessageAction {
  const _MessageAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      title: 'We hit a snag',
      subtitle: 'Something went wrong while loading the round data.',
      primaryAction: _MessageAction(label: 'Try again', onTap: onRetry),
    );
  }
}
