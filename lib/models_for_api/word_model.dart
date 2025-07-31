

class WordModel {
  final int id;
  final String text;
  final String image; // Image type is String
  final int level;

  WordModel({
    required this.id,
    required this.text,
    required this.image,
    required this.level,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'],
      text: json['text'],
      image: json['image'], // Image is String from server
      level: json['level'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'image': image, // Store String directly
      'level': level,
    };
  }

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'],
      text: map['text'],
      image: map['image'], // Retrieve String directly
      level: map['level'],
    );
  }
}
