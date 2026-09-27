import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/bubbly_button.dart';
import '../../widgets/common.dart';

/// Asks a grown-up question (multiplication) before opening parent areas,
/// purchases or settings.
Future<bool> showParentalGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: ParentalGate(
        onResult: (passed) => Navigator.of(context).pop(passed),
      ),
    ),
  );
  return ok ?? false;
}

class ParentalGate extends StatefulWidget {
  const ParentalGate({super.key, required this.onResult});

  final ValueChanged<bool> onResult;

  @override
  State<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  final _rng = Random();
  late int _a;
  late int _b;
  String _entry = '';
  int _shake = 0;
  int _fails = 0;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = _rng.nextInt(7) + 3;
    _b = _rng.nextInt(4) + 6;
    _entry = '';
  }

  void _press(String key) {
    setState(() {
      if (key == '⌫') {
        if (_entry.isNotEmpty) _entry = _entry.substring(0, _entry.length - 1);
        return;
      }
      if (_entry.length >= 3) return;
      _entry += key;
      final answer = '${_a * _b}';
      if (_entry.length >= answer.length) {
        if (_entry == answer) {
          widget.onResult(true);
        } else {
          _shake++;
          _fails++;
          if (_fails >= 3) {
            widget.onResult(false);
          } else {
            _newQuestion();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: AppColors.stories, size: 26),
                      const SizedBox(width: 8),
                      Text('Grown-ups only', style: KidText.display(22)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Please answer to continue:', style: KidText.body(16, color: AppColors.inkSoft)),
                  const SizedBox(height: 14),
                  Shake(
                    trigger: _shake,
                    child: Row(
                      children: [
                        Text('$_a × $_b = ', style: KidText.display(34, color: AppColors.stories)),
                        Container(
                          constraints: const BoxConstraints(minWidth: 76),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.stories.pastel,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(_entry.isEmpty ? ' ' : _entry, style: KidText.display(34)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => widget.onResult(false),
                    child: Text('Cancel', style: KidText.body(18, color: AppColors.inkSoft)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 216,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0'])
                    SizedBox(
                      width: 64,
                      height: 50,
                      child: Material(
                        color: k == '⌫' ? const Color(0xFFFFE3E3) : const Color(0xFFF1EDFF),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _press(k),
                          child: Center(child: Text(k, style: KidText.display(24))),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps [child] so that tapping it asks the parental gate first.
class GrownUpButton extends StatelessWidget {
  const GrownUpButton({super.key, required this.onPassed, this.dark = true});

  final VoidCallback onPassed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return BubblyButton(
      onTap: () async {
        if (await showParentalGate(context)) onPassed();
      },
      color: dark ? const Color(0xFF3B2A86) : Colors.white,
      depth: 4,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      gradient: false,
      semanticLabel: 'Grown-ups',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 20, color: dark ? Colors.white70 : AppColors.inkSoft),
          const SizedBox(width: 6),
          Text('Grown-ups', style: KidText.display(16, color: dark ? Colors.white : AppColors.ink, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
