// lib/models/feedback_model.dart
class FeedbackModel {
  final int? id;
  final String username;
  final String kesan;
  final String pesan;
  final DateTime createdAt;

  FeedbackModel({
    this.id,
    required this.username,
    required this.kesan,
    required this.pesan,
    required this.createdAt,
  });

  // Konversi dari Map (database) ke objek FeedbackModel
  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'],
      username: map['username'],
      kesan: map['kesan'],
      pesan: map['pesan'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Konversi dari objek FeedbackModel ke Map (untuk insert ke database)
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'kesan': kesan,
      'pesan': pesan,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
