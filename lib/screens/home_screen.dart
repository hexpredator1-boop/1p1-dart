import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../models/question.dart';
import '../logic/storage.dart';
import '../logic/question_generator.dart';
import '../widgets/keypad.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/trophy_sheet.dart';

const _ops = ['add', 'sub', 'mul', 'div'];
const _opNames = {'add': '+', 'sub': '−', 'mul': '×', 'div': '÷'};
const _opLabels = {'add': 'add', 'sub': 'sub', 'mul': 'mul', 'div': 'div'};

const _diffDesc = {
  'add': [
    'Warm up — single digit, sums up to 10',
    'Easy — single digit, sums up to 18',
    'Medium — 2-digit + 1-digit, no carrying',
    'Hard — 2-digit + 1-digit, with carrying',
    'Expert — 2-digit + 2-digit, with carrying',
  ],
  'sub': [
    'Warm up — single digit, small gaps',
    'Easy — single digit, all combos',
    'Medium — 2-digit minus 1-digit, no borrowing',
    'Hard — 2-digit minus 1-digit, with borrowing',
    'Expert — 2-digit minus 2-digit, with borrowing',
  ],
  'mul': [
    'Warm up — small single digits (2–4)',
    'Easy — single digit, up to 5×5',
    'Medium — single digit, full range 2–9',
    'Hard — 2-digit × 1-digit, no carrying',
    'Expert — 2-digit × 1-digit, with carrying',
  ],
  'div': [
    'Warm up — small divisors, result up to 5',
    'Easy — single digit ÷ single digit',
    'Medium — up to 81 ÷ 9, full range',
    'Hard — 2-digit ÷ 1-digit, clean',
    'Expert — 2-digit ÷ 2-digit, clean',
  ],
};

enum _Screen { home, question, end }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AppState _state;

  // Session state
  _Screen _screen = _Screen.home;
  List<Question> _questions = [];
  int _qIndex = 0;
  String _inputVal = '';
  int _penaltyMs = 0;
  bool _wrongLocked = false;

  // Timer
  DateTime? _timerStart;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  // End screen
  int _endPct = 0;
  int? _prevBest;
  bool _isNewBest = false;
  int _endActualMs = 0;

  // Wrong animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  bool _showWrong = false;

  @override
  void initState() {
    super.initState();
    _state = Storage.loadState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: -2.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 0.0), weight: 10),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Helpers ──
  String get _currentKey => '${_state.op}_${_state.difficulties[_state.op]}';
  int get _currentLevel => _state.difficulties[_state.op]!;

  String _formatElapsed(Duration d) {
    final ms = d.inMilliseconds;
    final m  = ms ~/ 60000;
    final s  = (ms % 60000) ~/ 1000;
    final cs = (ms % 1000) ~/ 10;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}:${cs.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'pm' : 'am';
    const months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
    return '$h:$m$ampm · ${months[d.month - 1]} ${d.day}/${d.year}';
  }

  // ── Session ──
  void _startSession() {
    final op = _state.op;
    final level = _state.difficulties[op]!;
    setState(() {
      _questions = pickQuestions(op, level);
      _qIndex = 0;
      _inputVal = '';
      _penaltyMs = 0;
      _wrongLocked = false;
      _showWrong = false;
      _screen = _Screen.question;
      _elapsed = Duration.zero;
    });
    _timerStart = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_timerStart!);
      });
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _finishSession() {
    final actualMs = DateTime.now().difference(_timerStart!).inMilliseconds;
    _stopTimer();

    final op = _state.op;
    final level = _state.difficulties[op]!;
    final goalSec = _state.goalFor(op, level);
    final key = _currentKey;
    final pct = calcScore(actualMs, _penaltyMs, _questions.length, goalSec);
    final bests = Storage.loadBests();
    final prevBest = bests[key];
    final isNew = prevBest == null || pct > prevBest;

    if (isNew) {
      Storage.saveBest(key, pct);
    }
    if (pct == 100) {
      Storage.savePerfect(key, goalSec);
    }

    setState(() {
      _endPct = pct;
      _prevBest = prevBest;
      _isNewBest = isNew;
      _endActualMs = actualMs;
      _screen = _Screen.end;
    });
  }

  void _handleInput(String digit) {
    if (_wrongLocked) return;
    if (digit == 'clear') {
      setState(() => _inputVal = '');
      return;
    }
    final q = _questions[_qIndex];
    final candidate = _inputVal + digit;
    final numVal = int.tryParse(candidate);
    if (numVal != null && numVal == q.answer) {
      setState(() => _inputVal = candidate);
      _qIndex++;
      if (_qIndex >= _questions.length) {
        _finishSession();
      } else {
        setState(() {
          _inputVal = '';
          _showWrong = false;
        });
      }
      return;
    }
    // Check impossible
    if (!q.answer.toString().startsWith(candidate)) {
      _triggerWrong(candidate);
      return;
    }
    setState(() => _inputVal = candidate);
  }

  void _triggerWrong(String badInput) {
    if (_wrongLocked) return;
    setState(() {
      _wrongLocked = true;
      _penaltyMs += wrongPenaltyMs;
      _inputVal = badInput;
      _showWrong = true;
    });
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() {
        _inputVal = '';
        _showWrong = false;
        _wrongLocked = false;
      });
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_screen != _Screen.question) return;
    if (event is! KeyDownEvent) return;
    final ch = event.character;
    if (ch != null && ch.contains(RegExp(r'[0-9]'))) {
      _handleInput(ch);
    } else if (event.logicalKey == LogicalKeyboardKey.backspace ||
               event.logicalKey == LogicalKeyboardKey.delete ||
               event.logicalKey == LogicalKeyboardKey.escape) {
      _handleInput('clear');
    }
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildCurrentScreen()),
              if (_screen != _Screen.question) _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_screen) {
      case _Screen.home:     return _buildHomeScreen();
      case _Screen.question: return _buildQuestionScreen();
      case _Screen.end:      return _buildEndScreen();
    }
  }

  // ────────────────────────────────────────────────
  // HOME SCREEN
  // ────────────────────────────────────────────────
  Widget _buildHomeScreen() {
    final op = _state.op;
    final level = _currentLevel;
    final bests = Storage.loadBests();
    final best = bests[_currentKey];
    final desc = _diffDesc[op]![level - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _opNames[op]!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      color: AppColors.text,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    best != null ? 'best: $best% · Lv$level' : 'no best yet',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: best != null ? AppColors.accent : AppColors.dim,
                      letterSpacing: 0.03,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _IconBtn(
                    icon: Icons.emoji_events_outlined,
                    onTap: () => _openTrophy(),
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.tune,
                    onTap: () => _openSettings(),
                  ),
                ],
              ),
            ],
          ),

          // Difficulty stepper
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIFFICULTY',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: AppColors.dim,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(5, (i) {
                    final lv = i + 1;
                    final isActive = lv == level;
                    final isFilled = lv < level;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _state.difficulties[op] = lv;
                            });
                            Storage.saveState(_state);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            height: 44,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF141A00)
                                  : isFilled
                                      ? const Color(0xFF0F1400)
                                      : AppColors.surface,
                              border: Border.all(
                                color: isActive
                                    ? AppColors.accent
                                    : isFilled
                                        ? const Color(0xFF2A3A00)
                                        : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Text(
                                '$lv',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  color: isActive
                                      ? AppColors.accent
                                      : isFilled
                                          ? const Color(0xFF4A6A00)
                                          : AppColors.dim,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: AppColors.dim,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),

          // Go button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                elevation: 0,
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // QUESTION SCREEN
  // ────────────────────────────────────────────────
  Widget _buildQuestionScreen() {
    final q = _questions[_qIndex];
    return Column(
      children: [
        // Timer bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text(
                _formatElapsed(_elapsed),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.accent,
                  letterSpacing: 0.05,
                ),
              ),
              const Spacer(),
              Text(
                '${_qIndex + 1} / ${_questions.length}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppColors.dim,
                  letterSpacing: 0.03,
                ),
              ),
            ],
          ),
        ),

        // Question display
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _showWrong ? AppColors.wrong : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      color: AppColors.text,
                      letterSpacing: -1,
                      height: 1,
                    ),
                    children: [
                      TextSpan(text: '${q.display}='),
                      TextSpan(
                        text: _inputVal.isEmpty ? ' ' : _inputVal,
                        style: TextStyle(
                          color: _showWrong ? AppColors.wrong : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Keypad
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Keypad(onKey: _handleInput),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────
  // END SCREEN
  // ────────────────────────────────────────────────
  Widget _buildEndScreen() {
    final ms = _endActualMs;
    final m  = ms ~/ 60000;
    final s  = (ms % 60000) ~/ 1000;
    final cs = (ms % 1000) ~/ 10;
    final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}:${cs.toString().padLeft(2, '0')}';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SCORE',
            style: TextStyle(
              fontFamily: 'sans-serif',
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: AppColors.dim,
              letterSpacing: 0.22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_endPct%',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 80,
              fontWeight: FontWeight.w300,
              color: AppColors.accent,
              letterSpacing: -4,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          if (_isNewBest) ...[
            Text(
              _prevBest != null ? 'prev best: $_prevBest%' : 'first record!',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: AppColors.accent,
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'NEW BEST',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bg,
                  letterSpacing: 0.12,
                ),
              ),
            ),
          ] else
            Text(
              _prevBest != null ? 'best: $_prevBest%' : '',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: AppColors.dim,
                letterSpacing: 0.04,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            timeStr,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.dim,
              letterSpacing: 0.04,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() => _screen = _Screen.home);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dim,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: const Text(
              'BACK',
              style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // BOTTOM NAV
  // ────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
        color: AppColors.bg,
      ),
      child: Row(
        children: _ops.map((op) {
          final isActive = op == _state.op;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _state.op = op);
                Storage.saveState(_state);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _opNames[op]!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: isActive ? AppColors.accent : AppColors.dim,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _opLabels[op]!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.12,
                      color: isActive ? AppColors.accent : AppColors.dim,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // SHEETS
  // ────────────────────────────────────────────────
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SettingsSheet(
        appState: _state,
        onSaved: (newState) {
          setState(() => _state = newState);
          Storage.saveState(newState);
        },
      ),
    );
  }

  void _openTrophy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TrophySheet(formatDateTime: _formatDateTime),
    );
  }
}

// ── Small icon button ──
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: AppColors.dim, size: 22),
      ),
    );
  }
}
