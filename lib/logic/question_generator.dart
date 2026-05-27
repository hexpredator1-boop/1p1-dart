import 'dart:math';
import '../models/question.dart';

const int sessionSize = 15;
const int wrongPenaltyMs = 300;

List<Question> _genAdd(int level) {
  final p = <Question>[];
  if (level == 1) {
    for (int a = 1; a <= 9; a++)
      for (int b = 1; b <= 9; b++)
        if (a + b <= 10) p.add(Question(display: '$a+$b', answer: a + b));
  } else if (level == 2) {
    // handled in pickQuestions
  } else if (level == 3) {
    for (int a = 10; a <= 99; a++)
      for (int b = 1; b <= 9; b++)
        if ((a % 10) + b <= 9) p.add(Question(display: '$a+$b', answer: a + b));
  } else if (level == 4) {
    for (int a = 10; a <= 99; a++)
      for (int b = 1; b <= 9; b++)
        if ((a % 10) + b >= 10) p.add(Question(display: '$a+$b', answer: a + b));
  } else {
    for (int a = 10; a <= 99; a++)
      for (int b = 10; b <= 99; b++)
        if ((a % 10) + (b % 10) >= 10) p.add(Question(display: '$a+$b', answer: a + b));
  }
  return p;
}

List<Question> _genSub(int level) {
  final p = <Question>[];
  if (level == 1) {
    for (int a = 2; a <= 9; a++)
      for (int b = 1; b < a; b++)
        if (a - b <= 5) p.add(Question(display: '$a\u2212$b', answer: a - b));
  } else if (level == 2) {
    for (int a = 2; a <= 9; a++)
      for (int b = 1; b < a; b++)
        p.add(Question(display: '$a\u2212$b', answer: a - b));
  } else if (level == 3) {
    for (int a = 10; a <= 99; a++)
      for (int b = 1; b <= 9; b++)
        if (a > b && (a % 10) >= b) p.add(Question(display: '$a\u2212$b', answer: a - b));
  } else if (level == 4) {
    for (int a = 10; a <= 99; a++)
      for (int b = 1; b <= 9; b++)
        if (a > b && (a % 10) < b) p.add(Question(display: '$a\u2212$b', answer: a - b));
  } else {
    for (int a = 10; a <= 99; a++)
      for (int b = 10; b < a; b++)
        if ((a % 10) < (b % 10)) p.add(Question(display: '$a\u2212$b', answer: a - b));
  }
  return p;
}

List<Question> _genMul(int level) {
  final p = <Question>[];
  if (level == 1) {
    for (int a = 2; a <= 4; a++)
      for (int b = 2; b <= 4; b++)
        p.add(Question(display: '$a\u00d7$b', answer: a * b));
  } else if (level == 2) {
    for (int a = 2; a <= 5; a++)
      for (int b = 2; b <= 5; b++)
        p.add(Question(display: '$a\u00d7$b', answer: a * b));
  } else if (level == 3) {
    for (int a = 2; a <= 9; a++)
      for (int b = 2; b <= 9; b++)
        p.add(Question(display: '$a\u00d7$b', answer: a * b));
  } else if (level == 4) {
    for (int a = 12; a <= 99; a++)
      for (int b = 2; b <= 9; b++)
        if ((a % 10) * b < 10) p.add(Question(display: '$a\u00d7$b', answer: a * b));
  } else {
    for (int a = 12; a <= 99; a++)
      for (int b = 2; b <= 9; b++)
        if ((a % 10) * b >= 10) p.add(Question(display: '$a\u00d7$b', answer: a * b));
  }
  return p;
}

List<Question> _genDiv(int level) {
  final p = <Question>[];
  if (level == 1) {
    for (int b = 2; b <= 5; b++)
      for (int ans = 1; ans <= 5; ans++)
        p.add(Question(display: '${b * ans}\u00f7$b', answer: ans));
  } else if (level == 2) {
    for (int b = 2; b <= 9; b++)
      for (int ans = 2; ans <= 9; ans++)
        p.add(Question(display: '${b * ans}\u00f7$b', answer: ans));
  } else if (level == 3) {
    for (int b = 2; b <= 9; b++)
      for (int ans = 2; ans <= 9; ans++)
        p.add(Question(display: '${b * ans}\u00f7$b', answer: ans));
  } else if (level == 4) {
    for (int b = 2; b <= 9; b++)
      for (int ans = 10; ans <= 99; ans++)
        if (b * ans <= 999) p.add(Question(display: '${b * ans}\u00f7$b', answer: ans));
  } else {
    for (int b = 10; b <= 99; b++)
      for (int ans = 2; ans <= 9; ans++) {
        final d = b * ans;
        if (d <= 999) p.add(Question(display: '$d\u00f7$b', answer: ans));
      }
  }
  return p;
}

List<Question> _buildPool(String op, int level) {
  switch (op) {
    case 'add': return _genAdd(level);
    case 'sub': return _genSub(level);
    case 'mul': return _genMul(level);
    case 'div': return _genDiv(level);
    default:    return [];
  }
}

List<Question> pickQuestions(String op, int level) {
  final rng = Random();

  // Addition level 2: hard8 + fillers
  if (op == 'add' && level == 2) {
    final hard8 = [
      Question(display: '8+7', answer: 15),
      Question(display: '8+6', answer: 14),
      Question(display: '7+6', answer: 13),
      Question(display: '8+5', answer: 13),
      Question(display: '5+7', answer: 12),
      Question(display: '4+8', answer: 12),
      Question(display: '3+8', answer: 11),
      Question(display: '4+7', answer: 11),
    ];
    final hardSet = hard8.map((h) => h.display).toSet();
    final fillerPool = _genAdd(1).where((q) => !hardSet.contains(q.display)).toList()..shuffle(rng);
    final fillerCount = sessionSize - hard8.length;
    final fillers = <Question>[];
    int fi = 0;
    while (fillers.length < fillerCount) {
      fillers.add(fillerPool[fi % fillerPool.length]);
      fi++;
    }
    final merged = [...hard8, ...fillers]..shuffle(rng);
    // Fix consecutive duplicates
    for (int i = 1; i < merged.length; i++) {
      if (merged[i].display == merged[i - 1].display) {
        for (int j = i + 1; j < merged.length; j++) {
          if (merged[j].display != merged[i - 1].display) {
            final tmp = merged[i]; merged[i] = merged[j]; merged[j] = tmp;
            break;
          }
        }
      }
    }
    return merged;
  }

  final pool = _buildPool(op, level);
  if (pool.isEmpty) return [];
  pool.shuffle(rng);
  final result = <Question>[];
  int idx = 0, attempts = 0;
  while (result.length < sessionSize && attempts < sessionSize * 20) {
    attempts++;
    final q = pool[idx % pool.length];
    if (result.isEmpty || q.display != result.last.display) {
      result.add(q);
    }
    idx++;
    if (idx > 0 && idx % pool.length == 0) pool.shuffle(rng);
  }
  return result;
}

int calcScore(int actualMs, int penaltyMs, int numQ, double goalSec) {
  final idealMs = numQ * goalSec * 1000;
  final effectiveMs = actualMs + penaltyMs;
  return (idealMs / effectiveMs * 100).round().clamp(0, 100);
}
