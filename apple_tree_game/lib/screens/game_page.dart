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

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late int _applesRemaining;
  bool _isPlayerTurn = true;
  String _statusMsg = '遊戲開始！輪到你了';
  int _countdown = 0;
  Timer? _timer;

  // 角色晃動動畫控制器
  late final AnimationController _playerCtrl;
  late final AnimationController _robotCtrl;

  @override
  void initState() {
    super.initState();
    _playerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
      ..stop();
    _robotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
      ..stop();
    _resetGame();
  }

  // --------------------------- Game Flow ---------------------------
  void _resetGame() {
    _timer?.cancel();
    _applesRemaining = Random().nextInt(9) + 26; // 26–34
    _isPlayerTurn = true;
    _statusMsg = '遊戲開始！輪到你了';
    _countdown = 0;
    setState(() {});
  }

  void _onPlayerPick(int picked) {
    if (!_isPlayerTurn || picked < 1 || picked > 3) return;
    _applyMove(picked, isPlayer: true);
  }

  void _applyMove(int picked, {required bool isPlayer}) {
    setState(() => _applesRemaining -= picked);

    _triggerShake(isPlayer); // 角色晃動

    if (_applesRemaining <= 0) {
      final loser = isPlayer ? '玩家' : '電腦';
      _statusMsg = '$loser 搖到最後一顆蘋果，輸了！';
      _timer?.cancel();
      _isPlayerTurn = false;
      return;
    }

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

  void _startAiTurn() {
    _countdown = 3;
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
    final target = (_applesRemaining - 1) % 4;
    if (target == 0) {
      return Random().nextInt(min(3, _applesRemaining)) + 1;
    }
    return target.clamp(1, 3);
  }

  // ---------------------- Animation helpers ------------------------
  void _triggerShake(bool isPlayer) {
    final ctrl = isPlayer ? _playerCtrl : _robotCtrl;
    ctrl
      ..reset()
      ..repeat(reverse: true);
    // 自動停止晃動
    Future.delayed(const Duration(milliseconds: 600), ctrl.stop);
  }

  // ----------------------------- UI --------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('蘋果樹 🍏 vs 🤖')),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/tree.png', fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                // ─── 上方：角色 + 蘋果樹 ─────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imgHeight = constraints.maxHeight * 0.6;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // 玩家
                          Positioned(
                            left: 16,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation: _playerCtrl,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, -8 * _playerCtrl.value),
                                child: child,
                              ),
                              child: GestureDetector(
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('剩餘蘋果：$_applesRemaining')),
                                ),
                                child: Image.asset('assets/player.png', height: imgHeight),
                              ),
                            ),
                          ),
                          // 機器人
                          Positioned(
                            right: 16,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation: _robotCtrl,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, -8 * _robotCtrl.value),
                                child: child,
                              ),
                              child: Image.asset('assets/robot.png', height: imgHeight),
                            ),
                          ),
                          // 蘋果樹 & 蘋果
                          Center(child: AppleTree(apples: _applesRemaining, key: ValueKey(_applesRemaining))),
                        ],
                      );
                    },
                  ),
                ),
                // ─── 底部控制區域 ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text('剩餘蘋果：$_applesRemaining', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      PickerControls(enabled: _isPlayerTurn && _applesRemaining > 0, onPick: _onPlayerPick),
                      const SizedBox(height: 12),
                      if (_countdown > 0)
                        Text('電腦將在 $_countdown 秒後搖蘋果…', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(_statusMsg, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _resetGame,
                        icon: const Icon(Icons.replay),
                        label: const Text('重新開始'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerCtrl.dispose();
    _robotCtrl.dispose();
    super.dispose();
  }
}