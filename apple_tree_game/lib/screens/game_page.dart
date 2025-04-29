import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/apple_tree.dart';
import '../widgets/picker_controls.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late int _applesRemaining;
  bool _isPlayerTurn = true;
  String _statusMsg = '遊戲開始！輪到你了';
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _timer?.cancel();
    _applesRemaining = Random().nextInt(9) + 26; // 26‑34
    _isPlayerTurn = true;
    _statusMsg = '遊戲開始！輪到你了';
    _countdown = 0;
    setState(() {});
  }

  // === Callback from child widget (lifting state up) ===
  void _onPlayerPick(int picked) {
    if (!_isPlayerTurn || picked < 1 || picked > 3) return;
    _applyMove(picked, isPlayer: true);
  }

  // === Core game logic ===
  void _applyMove(int picked, {required bool isPlayer}) {
    setState(() => _applesRemaining -= picked);

    // Check game end
    if (_applesRemaining <= 0) {
      final loser = isPlayer ? '玩家' : '電腦';
      _statusMsg = '$loser 搖到最後一顆蘋果，輸了！';
      _timer?.cancel();
      _isPlayerTurn = false;
      return;
    }

    // Switch turn
    _isPlayerTurn = !isPlayer;

    if (_isPlayerTurn) {
      _statusMsg = '輪到你了！';
      _countdown = 0;
      _timer?.cancel();
    } else {
      _statusMsg = '電腦思考中…';
      _startAiTurn();
    }
  }

  // === AI logic with Timer delay ===
  void _startAiTurn() {
    _countdown = 3; // 3‑second suspense
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
        final picked = _smartAiPick();
        _applyMove(picked, isPlayer: false);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  int _smartAiPick() {
    // Nim‑style: leave a multiple of 4 to the opponent when possible
    final target = (_applesRemaining - 1) % 4;
    if (target == 0) {
      return Random().nextInt(min(3, _applesRemaining)) + 1;
    }
    return target.clamp(1, 3);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('蘋果樹 🍏 vs 🤖')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AppleTree(
                  apples: _applesRemaining,
                  key: ValueKey(_applesRemaining),
                ),
              ),
            ),
            Text('剩餘蘋果：$_applesRemaining', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            PickerControls(
              enabled: _isPlayerTurn && _applesRemaining > 0,
              onPick: _onPlayerPick,
            ),
            const SizedBox(height: 12),
            if (_countdown > 0) Text('電腦將在 $_countdown 秒後搖蘋果…'),
            const SizedBox(height: 8),
            Text(_statusMsg, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _resetGame,
              icon: const Icon(Icons.replay),
              label: const Text('重新開始'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}