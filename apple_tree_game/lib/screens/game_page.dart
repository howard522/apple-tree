// lib/screens/game_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/apple_tree.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

/// 用來暫存「要落下的蘋果」資訊：對應 key 和它在樹上的 index
class _FallingApple {
  final Key key;
  final int index;
  _FallingApple(this.key, this.index);
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late int _applesRemaining;
  bool _isPlayerTurn = true;
  String _statusMsg = '遊戲開始！輪到你了';
  int _countdown = 0;
  Timer? _timer;

  // Dummy controller (若需要角色搖晃可留著，但目前用 Overlay 取代)
  late final AnimationController _dummyCtrl;

  // 全螢幕「跳出搖樹」圖片控制
  bool _showRollOverlay = false;
  String _overlayImagePath = '';

  // 初始化時就產生的「所有蘋果在樹上的相對偏移量」
  late List<Offset> _appleOffsets;

  // 要落下的蘋果列表：每個元素包含 Key 與在 _appleOffsets 的 index
  final List<_FallingApple> _fallingApples = [];

  // 蘋果落下時的 Y 座標範圍（相對於上半部高度）
  double _fallStartY = 0;
  double _fallEndY = 0;

  @override
  void initState() {
    super.initState();
    _dummyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..stop();
    _resetGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dummyCtrl.dispose();
    super.dispose();
  }

  // ───────────────── Game Flow ─────────────────

  /// 重置遊戲：隨機決定 26~34 顆蘋果，並產生對應的偏移量列表
  void _resetGame() {
    _timer?.cancel();
    _applesRemaining = Random().nextInt(9) + 26; // 26~34 顆
    _isPlayerTurn = true;
    _statusMsg = '遊戲開始！輪到你了';
    _countdown = 0;
    _showRollOverlay = false;
    _overlayImagePath = '';
    _fallingApples.clear();

    // 產生對應顆數的偏移量列表 (dx, dy)
    _appleOffsets = _generateAppleOffsets(_applesRemaining);

    setState(() {});
  }

  /// 使用與 AppleTree 相同的邏輯，給定 count，回傳對應長度的 Offset 陣列
  List<Offset> _generateAppleOffsets(int count) {
    final rnd = Random(count);
    final List<Offset> offsets = [];
    for (int i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * 140 - 70;  // 水平 ±70
      final dy = rnd.nextDouble() * 120 - 60;  // 垂直 ±60
      offsets.add(Offset(dx, dy));
    }
    return offsets;
  }

  void _onPlayerPick(int picked) {
    if (!_isPlayerTurn || picked < 1 || picked > 3) return;
    _startShakeAnimation(picked, isPlayer: true);
  }

  void _onAiPick(int picked) {
    _startShakeAnimation(picked, isPlayer: false);
  }

  /// 先顯示全螢幕 Overlay 圖片，接著依序播放 [count] 顆蘋果從樹上落下，
  /// 最後更新剩餘蘋果並進入下一回合或判定結束
  Future<void> _startShakeAnimation(int count, {required bool isPlayer}) async {
    // Step1：顯示全螢幕「搖樹」圖片
    setState(() {
      _showRollOverlay = true;
      _overlayImagePath = isPlayer
          ? 'assets/images/player_rolltree.png'
          : 'assets/images/computer_rolltree.png';
    });

    // 等待 300ms 讓使用者看到 Overlay
    await Future.delayed(const Duration(milliseconds: 300));

    // Step2：計算落下 Y 範圍 (根據螢幕高度的上半部)
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight = screenHeight * 0.60;
    _fallStartY = topHeight * 0.15; // 從樹冠上方約 15% 開始
    _fallEndY = topHeight * 0.65;   // 掉到樹幹底部附近

    // Step3：依序將 count 顆蘋果放入 _fallingApples，每顆間隔 300ms
    for (int i = 0; i < count; i++) {
      // 落下一顆時，對應的 index 我們取 i (即前 i 個位置)
      final key = UniqueKey();
      setState(() {
        _fallingApples.add(_FallingApple(key, i));
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 等所有蘋果落下動畫 (600ms) 完成
    await Future.delayed(const Duration(milliseconds: 600));

    // Step4：清除落下蘋果，並移除 Overlay
    setState(() {
      _fallingApples.clear();
      _showRollOverlay = false;
      _overlayImagePath = '';
    });

    // Step5：更新遊戲邏輯 (扣除蘋果、切換回合/結束)
    _completeShake(count, isPlayer: isPlayer);
  }

  void _completeShake(int picked, {required bool isPlayer}) {
    setState(() => _applesRemaining -= picked);

    if (_applesRemaining <= 0) {
      final loser = isPlayer ? '玩家' : '電腦';
      _statusMsg = '$loser 搖到最後一顆蘋果，輸了！';
      _timer?.cancel();
      _isPlayerTurn = false;
      setState(() {});
      return;
    }

    _isPlayerTurn = !isPlayer;
    if (_isPlayerTurn) {
      _statusMsg = '輪到你了！';
      _countdown = 0;
      _timer?.cancel();
      setState(() {});
    } else {
      _statusMsg = '電腦思考中…';
      _startAiCountDown();
      setState(() {});
    }
  }

  void _startAiCountDown() {
    _countdown = 3;
    setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
        final picked = _smartAiPick();
        _onAiPick(picked);
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

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight = screenHeight * 0.60;   // 上半部 60%
    final bottomHeight = screenHeight * 0.40; // 下半部 40%

    return Stack(
      children: [
        Column(
          children: [
            // ─── 上半部：樹 + 靜態蘋果 + 角色 + 動態落下蘋果 ───────────────────
            SizedBox(
              height: topHeight,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // (1) 樹 (BoxFit.contain，不擋底部空間)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/tree.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                    ),
                  ),

                  // (2) 靜態蘋果：使用 AppleTree，仍依 _applesRemaining 隨機顯示
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: topHeight * 0.40,
                    child: Center(
                      child: AppleTree(
                        apples: _applesRemaining,
                        key: ValueKey(_applesRemaining),
                      ),
                    ),
                  ),

                  // (3) 玩家: 左下方顯示靜態 player.png
                  Positioned(
                    left: 20,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/player.png',
                      height: topHeight * 0.45,
                    ),
                  ),

                  // (4) 電腦: 右下方顯示靜態 robot.png
                  Positioned(
                    right: 20,
                    bottom: 0,
                    child: Image.asset(
                      'assets/images/robot.png',
                      height: topHeight * 0.45,
                    ),
                  ),

                  // (5) 動態落下的蘋果，每一顆根據 _appleOffsets 和 index 決定 X 偏移
                  for (var falling in _fallingApples)
                    _buildFallingAppleWidget(falling.key, falling.index),
                ],
              ),
            ),

            // ─── 下半部：彩色背景 + 精美排版 ───────────────────
            SizedBox(
              height: bottomHeight,
              width: double.infinity,
              child: Container(
                color: theme.colorScheme.surfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 裝飾小條
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // (a) 剩餘蘋果卡片
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '剩餘蘋果：$_applesRemaining',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // (b) 搖蘋果按鈕區
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.background,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '請選擇要搖幾顆蘋果',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 搖 1 顆
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ElevatedButton(
                                    onPressed: (_isPlayerTurn && _applesRemaining > 0)
                                        ? () => _onPlayerPick(1)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      '搖 1 顆',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 搖 2 顆
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ElevatedButton(
                                    onPressed: (_isPlayerTurn && _applesRemaining > 0)
                                        ? () => _onPlayerPick(2)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      '搖 2 顆',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 搖 3 顆
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ElevatedButton(
                                    onPressed: (_isPlayerTurn && _applesRemaining > 0)
                                        ? () => _onPlayerPick(3)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      '搖 3 顆',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // (c) 倒數或狀態訊息
                    if (_countdown > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '電腦將在 $_countdown 秒後搖蘋果…',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        _statusMsg,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // (d) 重新開始按鈕
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _resetGame,
                        icon: const Icon(Icons.replay),
                        label: const Text('重新開始'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ─── 全螢幕 Overlay：顯示「搖樹」圖片 ───────────────────
        if (_showRollOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Image.asset(
                  _overlayImagePath,
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
      ], // Stack children 結束
    ); // return Stack 結束
  }

  /// 建立一顆「落下的蘋果」動畫 Widget
  Widget _buildFallingAppleWidget(Key key, int index) {
    // 將 offset 從 _appleOffsets 中取出
    final offset = _appleOffsets[index];
    // 以 tween 動畫從 _fallStartY 掉到 _fallEndY，水平位置固定在 tree center + offset.dx
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween<double>(begin: _fallStartY, end: _fallEndY),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeIn,
      builder: (context, value, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final startX = (screenWidth * 0.5) + offset.dx;
        return Positioned(
          top: value,
          left: startX,
          child: child!,
        );
      },
      child: Image.asset(
        'assets/images/apple.png',
        width: 32,
        height: 32,
      ),
      onEnd: () {
        // 動畫結束後移除該蘋果
        setState(() {
          _fallingApples.removeWhere((fa) => fa.key == key);
        });
      },
    );
  }
}
