/// Log Model
/// Represents a system log entry
class LogModel {
  final String id;
  final String userId;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  LogModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
    this.metadata,
  });

  /// Create LogModel from JSON
  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      userId: json['userID'] as String,
      action: json['action'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert LogModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userID': userId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  LogModel copyWith({
    String? id,
    String? userId,
    String? action,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return LogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  String toString() {
    return 'LogModel(action: $action, user: $userId, time: $timeAgo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
