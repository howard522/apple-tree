// lib/screens/game_page.dart
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

  // 角色動畫控制器
  late final AnimationController _playerCtrl;
  late final AnimationController _robotCtrl;

  // Day1 要新增的兩個狀態：玩家／電腦是否正在搖晃 (affect which image to show)
  bool _playerRolling = false;
  bool _robotRolling = false;

  @override
  void initState() {
    super.initState();
    // 初始化動畫控制器
    _playerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..stop();
    _robotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..stop();
    _resetGame();
  }

  // ────────────────────────── Game Flow ──────────────────────────
  void _resetGame() {
    _timer?.cancel();
    _applesRemaining = Random().nextInt(9) + 26; // 26–34
    _isPlayerTurn = true;
    _statusMsg = '遊戲開始！輪到你了';
    _countdown = 0;
    // Day1：確保「搖晃圖」回到靜態
    _playerRolling = false;
    _robotRolling = false;
    setState(() {});
  }

  void _onPlayerPick(int picked) {
    if (!_isPlayerTurn || picked < 1 || picked > 3) return;
    _applyMove(picked, isPlayer: true);
  }

  void _applyMove(int picked, {required bool isPlayer}) {
    setState(() => _applesRemaining -= picked);

    // Day1：觸發搖晃動畫與圖片切換
    _triggerShake(isPlayer);

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

  // Day1：改造 _triggerShake，加入顯示搖晃圖片的邏輯
  void _triggerShake(bool isPlayer) {
    final ctrl = isPlayer ? _playerCtrl : _robotCtrl;

    // Step1：先把對應的 "rolling" flag 開啟，觸發 setState 讓 build 中切換到搖晃圖
    setState(() {
      if (isPlayer) {
        _playerRolling = true;
      } else {
        _robotRolling = true;
      }
    });

    // Step2：動畫重置並重播
    ctrl
      ..reset()
      ..repeat(reverse: true);

    // Step3：600ms 後停止動畫，並把 "rolling" flag 關掉
    Future.delayed(const Duration(milliseconds: 600), () {
      ctrl.stop();
      setState(() {
        if (isPlayer) {
          _playerRolling = false;
        } else {
          _robotRolling = false;
        }
      });
    });
  }

  // ───────────────────────────── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('蘋果樹 🍏 vs 🤖')),
      body: Stack(
        children: [
          // 背景樹 (繼續使用原本的背景)
          Positioned.fill(child: Image.asset('assets/images/tree.png', fit: BoxFit.cover)),
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
                          // 玩家 (左邊)
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
                                child: Image.asset(
                                  // Day1：正在搖晃就顯示 player_rolltree.png，否則顯示 player.png
                                  _playerRolling
                                      ? 'assets/images/player_rolltree.png'
                                      : 'assets/images/player.png',
                                  height: imgHeight,
                                ),
                              ),
                            ),
                          ),

                          // 電腦 (右邊)
                          Positioned(
                            right: 16,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation: _robotCtrl,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, -8 * _robotCtrl.value),
                                child: child,
                              ),
                              child: Image.asset(
                                // Day1：正在搖晃就顯示 computer_rolltree.png，否則顯示 robot.png
                                _robotRolling
                                    ? 'assets/images/computer_rolltree.png'
                                    : 'assets/images/robot.png',
                                height: imgHeight,
                              ),
                            ),
                          ),

                          // 中間蘋果樹 & 蘋果
                          Center(
                            child: AppleTree(
                              apples: _applesRemaining,
                              key: ValueKey(_applesRemaining),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ─── 底部：剩餘蘋果數、按鈕、狀態訊息、重置 ─────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        '剩餘蘋果：$_applesRemaining',
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      PickerControls(
                        enabled: _isPlayerTurn && _applesRemaining > 0,
                        onPick: _onPlayerPick,
                      ),
                      const SizedBox(height: 12),
                      if (_countdown > 0)
                        Text(
                          '電腦將在 $_countdown 秒後搖蘋果…',
                          style: theme.textTheme.titleMedium,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMsg,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
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
