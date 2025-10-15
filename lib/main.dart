import 'package:cod/classes/player_manager.dart';
import 'package:cod/theme/colors.dart';
import 'package:cod/views/add_player.dart';
import 'package:cod/views/game_round.dart';
import 'package:cod/views/player_overview.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CallOfDeeno());
}

class CallOfDeeno extends StatefulWidget {
  const CallOfDeeno({super.key});

  @override
  State<CallOfDeeno> createState() => _CallOfDeenoState();
}

class _CallOfDeenoState extends State<CallOfDeeno> {
  late final PlayerManager _playerManager = PlayerManager();

  @override
  void dispose() {
    _playerManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayerScope(
      manager: _playerManager,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Call of Deeno',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Nunito',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
            primary: AppColors.primary,
            secondary: AppColors.primary,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            hintStyle: const TextStyle(color: Colors.white54),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: AppColors.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          textTheme: const TextTheme(
            displaySmall: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
            bodyMedium: TextStyle(color: Colors.white70),
          ),
        ),
        onGenerateRoute: _onGenerateRoute,
        home: const PlayerOverviewScreen(),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AddPlayerScreen.routeName:
        return MaterialPageRoute(builder: (_) => const AddPlayerScreen());
      case GameRoundBeforeScreen.routeName:
        return MaterialPageRoute(builder: (_) => const GameRoundBeforeScreen());
      default:
        return null;
    }
  }
}
