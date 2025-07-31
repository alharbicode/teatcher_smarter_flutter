class SentenceModel {
  final int id;
  final String text;
  final int level;

  SentenceModel({
    required this.id,
    required this.text,
    required this.level,
  });

  factory SentenceModel.fromJson(Map<String, dynamic> json) {
    return SentenceModel(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      level: json['level'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'level': level,
    };
  }

  factory SentenceModel.fromMap(Map<String, dynamic> map) {
    return SentenceModel(
      id: map['id'] ?? 0,
      text: map['text'] ?? '',
      level: map['level'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'SentenceModel(id: $id, text: $text, level: $level)';
  }
}
