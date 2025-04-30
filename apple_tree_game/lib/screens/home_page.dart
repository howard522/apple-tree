import 'package:flutter/material.dart';
import 'game_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('蘋果樹遊戲')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/tree.png', height: 180),
              const SizedBox(height: 32),
              Text('🎮 玩法說明', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                '樹上隨機生成 26‒34 顆蘋果，您與電腦輪流搖 1‒3 顆，搖到最後一顆的人輸！',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('開始遊戲'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GamePage())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}