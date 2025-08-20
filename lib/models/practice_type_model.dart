import 'dart:convert';

class PracticeType {
  final int? id;
  final String type;
  final String icon; // Store icon data as string, e.g., 'Icons.calculate'
  final int color; // Store color as int
  final String description;
  final String emoji;
  final List<String> subTypes;
  final DateTime? createdAt;

  PracticeType({
    this.id,
    required this.type,
    required this.icon,
    required this.color,
    required this.description,
    required this.emoji,
    required this.subTypes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'icon': icon,
      'color': color,
      'description': description,
      'emoji': emoji,
      'sub_types': jsonEncode(subTypes),
      'created_at': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory PracticeType.fromMap(Map<String, dynamic> map) {
    return PracticeType(
      id: map['id'],
      type: map['type'],
      icon: map['icon'],
      color: map['color'],
      description: map['description'],
      emoji: map['emoji'],
      subTypes: List<String>.from(jsonDecode(map['sub_types'])),
      createdAt: map['created_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['created_at']) : null,
    );
  }
}
