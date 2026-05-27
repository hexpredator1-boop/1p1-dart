class AppState {
  String op;
  Map<String, int> difficulties;
  Map<String, double> goalTimes;

  static const _defaultGoalTimes = {
    'add': 0.9, 'sub': 1.2, 'mul': 2.0, 'div': 2.5,
  };

  AppState({
    required this.op,
    required this.difficulties,
    required this.goalTimes,
  });

  factory AppState.defaults() {
    final goalTimes = <String, double>{};
    for (final op in ['add', 'sub', 'mul', 'div']) {
      for (int lv = 1; lv <= 5; lv++) {
        goalTimes['${op}_$lv'] = _defaultGoalTimes[op]!;
      }
    }
    return AppState(
      op: 'add',
      difficulties: {'add': 1, 'sub': 1, 'mul': 1, 'div': 1},
      goalTimes: goalTimes,
    );
  }

  double goalFor(String op, int level) {
    final key = '${op}_$level';
    return goalTimes[key] ?? _defaultGoalTimes[op] ?? 0.9;
  }

  AppState copyWith({String? op, Map<String, int>? difficulties, Map<String, double>? goalTimes}) {
    return AppState(
      op: op ?? this.op,
      difficulties: difficulties ?? Map.from(this.difficulties),
      goalTimes: goalTimes ?? Map.from(this.goalTimes),
    );
  }

  Map<String, dynamic> toJson() => {
    'op': op,
    'difficulties': difficulties,
    'goalTimes': goalTimes.map((k, v) => MapEntry(k, v)),
  };

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      op: json['op'] as String? ?? 'add',
      difficulties: (json['difficulties'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          {'add': 1, 'sub': 1, 'mul': 1, 'div': 1},
      goalTimes: (json['goalTimes'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
    );
  }
}
