import 'package:flutter/material.dart';

class PickerControls extends StatelessWidget {
  final bool enabled;
  final ValueChanged<int> onPick; // callback => lifting‑state‑up
  const PickerControls({super.key, required this.enabled, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: List.generate(3, (i) {
        final pick = i + 1;
        return ElevatedButton(
          onPressed: enabled ? () => onPick(pick) : null,
          child: Text('搖 $pick 顆'),
        );
      }),
    );
  }
}