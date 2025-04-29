import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const AppleTreeApp());

class AppleTreeApp extends StatelessWidget {
  const AppleTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '蘋果樹',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const AppleTreeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppleTreeGame extends StatefulWidget {
  const AppleTreeGame({super.key});

  @override
  State<AppleTreeGame> createState() => _AppleTreeGameState();
}

class _AppleTreeGameState extends State<AppleTreeGame> {
  static const _minApples = 26;
  static const _maxApples = 34;
  static const _turnSeconds = 10;

  final _rand = Random();
  late int _apples;
  late bool _playerTurn;
  String _statusMsg = '';
  int _countdown = _turnSeconds;
  Timer? _countTimer;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  void dispose() {
    _countTimer?.cancel();
    super.dispose();
  }

  void _resetGame() {
    _apples = _rand.nextInt(_maxApples - _minApples + 1) + _minApples;
    _playerTurn = true;
    _statusMsg = '遊戲開始！目前有$_apples顆蘋果';
    _startCountdown();
    setState(() {});
  }

  void _startCountdown() {
    _countTimer?.cancel();
    _countdown = _turnSeconds;
    _countTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown == 0) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _handleTimeout() {
    if (_apples > 0) {
      _endGame(_playerTurn ? '時間到！你超時了，電腦獲勝。' : '電腦超時，你贏了！');
    }
  }

  void _playerShake(int amount) {
    if (!_playerTurn || _apples <= 0) return;
    _applyShake(amount, isPlayer: true);
  }

  void _applyShake(int amount, {required bool isPlayer}) {
    setState(() {
      _apples -= amount;
      _statusMsg = '${isPlayer ? '你' : '電腦'}搖下$amount顆蘋果，剩餘$_apples顆';
    });

    if (_apples <= 0) {
      _endGame(isPlayer ? '你搖下最後一顆蘋果，遊戲失敗！' : '電腦搖下最後一顆蘋果，你獲勝！');
      return;
    }

    // Switch turns
    _playerTurn = !_playerTurn;
    _startCountdown();

    if (!_playerTurn) {
      _computerMove();
    }
  }

  void _computerMove() {
    // 模擬思考時間
    Timer(const Duration(seconds: 1), () {
      if (!mounted || _apples <= 0) return;
      final take = _rand.nextInt(3) + 1;
      _applyShake(min(take, _apples), isPlayer: false);
    });
  }

  void _endGame(String msg) {
    _countTimer?.cancel();
    setState(() {
      _statusMsg = msg;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('遊戲結束'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetGame();
            },
            child: const Text('再玩一次'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('蘋果樹 Apple Tree')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '剩餘蘋果：$_apples',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _playerTurn ? '你的回合' : '電腦思考中…',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '倒數：$_countdown 秒',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PlayerControls(
              enabled: _playerTurn && _apples > 0,
              onShake: _playerShake,
            ),
            const Spacer(),
            Text(
              _statusMsg,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.onShake,
    required this.enabled,
  });

  final void Function(int) onShake; // callback to parent (lifting state up)
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        3,
        (idx) => ElevatedButton(
          onPressed: enabled ? () => onShake(idx + 1) : null,
          child: Text('搖 ${idx + 1} 顆'),
        ),
      ),
    );
  }
}
