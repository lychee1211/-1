// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_record.dart';

class StorageService {
  // SharedPreferences 的 key 名
  static const String _key = 'daily_records';

  /// 获取所有记录（按日期倒序，最新的在前面）
  Future<List<DailyRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    final records = jsonList
        .map((item) => DailyRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    // 按日期倒序排列
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// 保存一条记录（如果同日期已存在，则覆盖更新）
  Future<void> saveRecord(DailyRecord record) async {
    final records = await getAllRecords();

    // 查找是否已有同一天的记录
    final index = records.indexWhere((r) => r.id == record.id);

    if (index >= 0) {
      // 覆盖旧记录
      records[index] = record;
    } else {
      // 新增记录
      records.add(record);
    }

    await _saveAll(records);
  }

  /// 删除指定日期的记录
  Future<void> deleteRecord(String id) async {
    final records = await getAllRecords();
    records.removeWhere((r) => r.id == id);
    await _saveAll(records);
  }

  /// 获取指定日期的记录（找不到返回 null）
  Future<DailyRecord?> getRecordByDate(DateTime date) async {
    final id = _dateToId(date);
    final records = await getAllRecords();
    try {
      return records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 导出所有数据为 JSON 字符串（用于备份）
  Future<String> exportAllData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '[]';
  }

  /// 导入 JSON 字符串数据（用于恢复备份，会覆盖现有数据）
  Future<int> importData(String jsonString) async {
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    final records = jsonList
        .map((item) => DailyRecord.fromJson(item as Map<String, dynamic>))
        .toList();

    await _saveAll(records);
    return records.length;
  }

  // ── 内部方法 ──────────────────────────

  /// 将整个列表序列化后写入 SharedPreferences
  Future<void> _saveAll(List<DailyRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = records.map((r) => r.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  /// 日期转 ID 字符串，如 "2026-05-08"
  static String _dateToId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 生成今天的 ID
  static String todayId() => _dateToId(DateTime.now());
}
