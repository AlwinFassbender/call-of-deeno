import 'package:cod/theme/colors.dart';
import 'package:flutter/material.dart';

class GameRoundBeforeScreen extends StatelessWidget {
  const GameRoundBeforeScreen({super.key});

  static const routeName = '/game-round/before';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Round 3',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  _PlayerChip(name: "Taylor's Turn"),
                  Spacer(),
                  _TimerBadge(time: '00:24'),
                ],
              ),
              const SizedBox(height: 18),
              Column(
                children: [
                  _RoundCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text('Your task', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                        const SizedBox(height: 12),
                        const Text(
                          "What’s a habit you’re trying to build this month, and how’s it going so far?",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1526657782461-9fe13402a841?auto=format&fit=crop&w=800&q=80',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: const [
              Expanded(
                child: _ResultChoiceButton(
                  label: 'Completed',
                  icon: Icons.check_circle_outline,
                  backgroundColor: Color(0xFF0A2E27),
                  foregroundColor: Color(0xFF4EE08C),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _ResultChoiceButton(
                  label: 'Failed',
                  icon: Icons.cancel_outlined,
                  backgroundColor: Color(0xFF331820),
                  foregroundColor: Color(0xFFFF6C7A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameRoundAfterScreen extends StatelessWidget {
  const GameRoundAfterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Round 3',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  _PlayerChip(name: "Taylor's Result"),
                  Spacer(),
                  _TimerBadge(time: '00:00'),
                ],
              ),
              const SizedBox(height: 18),
              Column(
                children: [
                  _RoundCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF153D2A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(color: Color(0xFF52E39E), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Reward', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                        const SizedBox(height: 12),
                        const Text(
                          "Taylor earned 2 points! Hand out a high-five and pass the phone to the next player.",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?auto=format&fit=crop&w=800&q=80',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(24, 0, 24, 24),
          child: ElevatedButton(onPressed: () {}, child: const Text('Next Task')),
        ),
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
  const _PlayerChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
          ),
        ),
        const SizedBox(width: 12),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ResultChoiceButton extends StatelessWidget {
  const _ResultChoiceButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
