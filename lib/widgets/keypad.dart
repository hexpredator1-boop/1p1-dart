import 'package:flutter/material.dart';
import '../theme.dart';

class Keypad extends StatelessWidget {
  final void Function(String) onKey;
  const Keypad({super.key, required this.onKey});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final keyH = constraints.maxWidth / 3 / 1.6;
      return Column(
        children: [
          _row(['7', '8', '9'], keyH),
          const SizedBox(height: 8),
          _row(['4', '5', '6'], keyH),
          const SizedBox(height: 8),
          _row(['1', '2', '3'], keyH),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(flex: 2, child: _Key(label: '0', onTap: () => onKey('0'), height: 52, isWide: true)),
              const SizedBox(width: 8),
              Expanded(flex: 1, child: _Key(label: 'CLR', onTap: () => onKey('clear'), height: 52, isClear: true)),
            ],
          ),
        ],
      );
    });
  }

  Widget _row(List<String> keys, double h) {
    return Row(
      children: keys.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
            child: _Key(label: e.value, onTap: () => onKey(e.value), height: h),
          ),
        );
      }).toList(),
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  final bool isWide;
  final bool isClear;

  const _Key({
    required this.label,
    required this.onTap,
    required this.height,
    this.isWide = false,
    this.isClear = false,
  });

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        height: widget.height,
        transform: _pressed
            ? (Matrix4.identity()..scale(0.93))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF1A1A1A)
              : widget.isClear
                  ? Colors.transparent
                  : AppColors.surface,
          border: Border.all(
            color: _pressed ? const Color(0xFF1E1E1E) : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: widget.isClear ? 'sans-serif' : 'monospace',
              fontSize: widget.isClear ? 13 : 24,
              fontWeight: widget.isClear ? FontWeight.w700 : FontWeight.w400,
              color: _pressed
                  ? const Color(0xFF888888)
                  : widget.isClear
                      ? AppColors.dim
                      : AppColors.text,
              letterSpacing: widget.isClear ? 0.12 : 0,
            ),
          ),
        ),
      ),
    );
  }
}
