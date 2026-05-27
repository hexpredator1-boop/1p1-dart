import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../logic/storage.dart';

const _opNames = {'add': '+', 'sub': '−', 'mul': '×', 'div': '÷'};

class SettingsSheet extends StatefulWidget {
  final AppState appState;
  final void Function(AppState) onSaved;

  const SettingsSheet({super.key, required this.appState, required this.onSaved});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController _ctrl;
  String _error = '';
  String _warning = '';

  String get _key => '${widget.appState.op}_${widget.appState.difficulties[widget.appState.op]}';
  double get _currentGoal => widget.appState.goalFor(widget.appState.op, widget.appState.difficulties[widget.appState.op]!);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _currentGoal.toString());
    _ctrl.addListener(_onInput);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onInput() {
    final val = double.tryParse(_ctrl.text);
    setState(() {
      _error = '';
      _warning = (val != null && val > 0 && val != _currentGoal)
          ? 'Changing goal time will reset Level ${widget.appState.difficulties[widget.appState.op]} highscore.'
          : '';
    });
  }

  void _save() {
    final raw = _ctrl.text.trim();
    final val = double.tryParse(raw);
    if (raw.isEmpty || val == null || val <= 0) {
      setState(() => _error = 'Must be a number greater than 0.');
      return;
    }
    final newGoal = (val * 100).round() / 100;
    final newState = widget.appState.copyWith(
      goalTimes: Map.from(widget.appState.goalTimes)..[_key] = newGoal,
    );
    if (newGoal != _currentGoal) {
      Storage.clearBest(_key);
    }
    widget.onSaved(newState);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final op = widget.appState.op;
    final level = widget.appState.difficulties[op]!;
    final title = '${_opNames[op]} — Settings';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.dim,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Goal time per question (seconds)',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: AppColors.text,
                    letterSpacing: 0.04,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _error.isNotEmpty ? AppColors.wrong : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _error.isNotEmpty ? AppColors.wrong : AppColors.accent,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      's',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        color: AppColors.dim,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_error.isNotEmpty)
                  Text(_error, style: const TextStyle(fontSize: 11, color: Color(0xFFC04040), letterSpacing: 0.04)),
                if (_warning.isNotEmpty)
                  Text(_warning, style: const TextStyle(fontSize: 11, color: AppColors.dim, letterSpacing: 0.04)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
