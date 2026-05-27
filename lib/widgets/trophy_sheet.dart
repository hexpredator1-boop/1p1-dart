import 'package:flutter/material.dart';
import '../theme.dart';
import '../logic/storage.dart';

const _ops = ['add', 'sub', 'mul', 'div'];
const _opNames = {'add': '+', 'sub': '−', 'mul': '×', 'div': '÷'};
const _opLabels = {'add': 'ADD', 'sub': 'SUB', 'mul': 'MUL', 'div': 'DIV'};

class TrophySheet extends StatefulWidget {
  final String Function(int) formatDateTime;
  const TrophySheet({super.key, required this.formatDateTime});

  @override
  State<TrophySheet> createState() => _TrophySheetState();
}

class _TrophySheetState extends State<TrophySheet> {
  late Map<String, Map<String, dynamic>> _perfect;
  final Set<String> _open = {};

  @override
  void initState() {
    super.initState();
    _perfect = Storage.loadPerfect();
    // Auto-open ops that have records
    for (final op in _ops) {
      for (int lv = 1; lv <= 5; lv++) {
        if (_perfect.containsKey('${op}_$lv')) {
          _open.add(op);
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Text(
                  'PERFECT SCORES',
                  style: TextStyle(
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: _ops.map((op) {
                  final records = <Map<String, dynamic>>[];
                  for (int lv = 1; lv <= 5; lv++) {
                    final k = '${op}_$lv';
                    if (_perfect.containsKey(k)) {
                      records.add({'lv': lv, ..._perfect[k]!});
                    }
                  }
                  final isOpen = _open.contains(op);
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          if (isOpen) _open.remove(op); else _open.add(op);
                        }),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Text(
                                '${_opNames[op]} ${_opLabels[op]}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: records.isNotEmpty ? AppColors.text : AppColors.dim,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                isOpen ? Icons.expand_less : Icons.expand_more,
                                color: AppColors.dim,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOpen)
                        records.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(bottom: 12, left: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('—', style: TextStyle(color: AppColors.dim, fontFamily: 'monospace')),
                                ),
                              )
                            : Column(
                                children: records.map((r) {
                                  final ts = r['ts'] as int;
                                  final goal = r['goalSec'];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10, left: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Lv${r['lv']}',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${goal}s',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 14,
                                            color: AppColors.dim,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          widget.formatDateTime(ts),
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: AppColors.dim,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      Container(height: 1, color: AppColors.border),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
