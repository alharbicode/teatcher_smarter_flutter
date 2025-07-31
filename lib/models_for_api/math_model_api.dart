class MathModelApi {
  final int id;
  final int arithmeticOperations;
  final int num1;
  final int num2;
  final List<String> steps;
  final int level;

  MathModelApi({
    required this.id,
    required this.arithmeticOperations,
    required this.num1,
    required this.num2,
    required this.steps,
    required this.level,
  });

  factory MathModelApi.fromJson(Map<String, dynamic> json) {
    return MathModelApi(
      id: json['id'],
      arithmeticOperations: json['arithmeticOperations'],
      num1: json['num1'],
      num2: json['num2'],
      steps: List<String>.from(json['steps']),
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arithmeticOperations': arithmeticOperations,
      'num1': num1,
      'num2': num2,
      'steps': steps,
      'level': level,
    };
  }

  factory MathModelApi.fromMap(Map<String, dynamic> map) {
    return MathModelApi(
      id: map['id'],
      arithmeticOperations: map['arithmeticOperations'],
      num1: map['num1'],
      num2: map['num2'],
      steps: (map['steps'] as String).split('||'),
      level: map['level'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arithmeticOperations': arithmeticOperations,
      'num1': num1,
      'num2': num2,
      'steps': steps.join('||'),
      'level': level,
    };
  }

  String get operationSymbol {
    switch (arithmeticOperations) {
      case 0:
        return '+';
      case 1:
        return '-';
      case 2:
        return '×';
      case 3:
        return '÷';
      default:
        return '+';
    }
  }

  double get result {
    switch (arithmeticOperations) {
      case 0:
        return (num1 + num2).toDouble();
      case 1:
        return (num1 - num2).toDouble();
      case 2:
        return (num1 * num2).toDouble();
      case 3:
        return (num1 / num2);
      default:
        return 0;
    }
  }
}
