// lib/models/daily_record.dart

/// 心情枚举
enum MoodType {
  happy('happy', '😊', '开心'),
  calm('calm', '😌', '平静'),
  tired('tired', '😪', '疲惫'),
  emo('emo', '🥺', '低落'),
  angry('angry', '😤', '生气');

  const MoodType(this.value, this.emoji, this.label);
  final String value;
  final String emoji;
  final String label;

  /// 根据字符串反查枚举
  static MoodType fromValue(String value) {
    return MoodType.values.firstWhere(
      (m) => m.value == value,
      orElse: () => MoodType.calm,
    );
  }
}

/// 每日记录数据模型
class DailyRecord {
  final String id; // 以日期字符串 "2026-05-08" 作为唯一 ID
  final DateTime date;
  final MoodType mood;
  final Map<String, bool> habits;
  final String content;
  final String? imagePath; // 本地图片路径，可为空

  DailyRecord({
    required this.id,
    required this.date,
    required this.mood,
    required this.habits,
    this.content = '',
    this.imagePath,
  });

  /// 从 JSON Map 反序列化
  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: MoodType.fromValue(json['mood'] as String),
      habits: Map<String, bool>.from(json['habits'] as Map),
      content: json['content'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
    );
  }

  /// 序列化为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood.value,
      'habits': habits,
      'content': content,
      'imagePath': imagePath,
    };
  }

  /// 复制并修改（用于编辑场景）
  DailyRecord copyWith({
    String? id,
    DateTime? date,
    MoodType? mood,
    Map<String, bool>? habits,
    String? content,
    String? imagePath,
    bool clearImage = false,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      habits: habits ?? this.habits,
      content: content ?? this.content,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  /// 预设的三个习惯键名
  static const List<MapEntry<String, String>> presetHabits = [
    MapEntry('drink_water', '💧 喝水'),
    MapEntry('sleep_early', '🌙 早睡'),
    MapEntry('exercise', '🏃 运动'),
  ];
}
