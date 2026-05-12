// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/daily_record.dart';
import 'services/storage_service.dart';
import 'widgets/check_in_sheet.dart';
import 'pages/settings_page.dart';

// ═══════════════════════════════════════════
// 全局颜色常量
// ═══════════════════════════════════════════

class AppColors {
  AppColors._();

  static const Color bgGreen = Color(0xFFE8F5E9);
  static const Color cardYellow = Color(0xFFFFFACD);
  static const Color textBrown = Color(0xFF5C4033);
  static const Color textMuted = Color(0xFF9E8E7E);

  static Color shadowColor = Colors.black.withOpacity(0.05);
  static Color glassOverlay = Colors.white.withOpacity(0.45);

  static const Map<MoodType, Color> moodColors = {
    MoodType.happy: Color(0xFFFFF9C4),
    MoodType.calm: Color(0xFFC8E6C9),
    MoodType.tired: Color(0xFFD1C4E9),
    MoodType.emo: Color(0xFFBBDEFB),
    MoodType.angry: Color(0xFFFFCDD2),
  };
}

// ═══════════════════════════════════════════
// 全局样式
// ═══════════════════════════════════════════

class AppStyle {
  AppStyle._();

  static const double radius = 24.0;
  static BorderRadius get borderRadius => BorderRadius.circular(radius);

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.cardYellow,
        borderRadius: borderRadius,
        boxShadow: softShadow,
      );
}

// ═══════════════════════════════════════════
// 应用入口
// ═══════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '治愈手帐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cardYellow,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: AppColors.textBrown,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textBrown,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textBrown,
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ═══════════════════════════════════════════
// 主页
// ═══════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _storage = StorageService();
  List<DailyRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 加载所有记录
  Future<void> _loadRecords() async {
    final records = await _storage.getAllRecords();
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  /// 打开签到弹窗
  void _openCheckIn({DailyRecord? existingRecord}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckInSheet(
        existingRecord: existingRecord,
        onSaved: _loadRecords,
      ),
    );
  }

  // ── 格式化日期 ──
  String _formatDate(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}年${date.month}月${date.day}日 $weekday';
  }

  // ── 构建 UI ──────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: AppColors.textMuted,
            size: 22,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : _buildTimeline(),
      // ── FAB ──
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCheckIn(),
        backgroundColor: AppColors.cardYellow,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.textBrown,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── 空状态 ──

  Widget _buildEmptyState() {
    return Center(
      child: GestureDetector(
        onTap: () => _openCheckIn(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.cardYellow,
                shape: BoxShape.circle,
                boxShadow: AppStyle.softShadow,
              ),
              child: const Center(
                child: Text('😊', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '今天过得好吗？',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '点我开始记录吧～',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // ── 时间轴列表 ──

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(_records[index], index);
      },
    );
  }

  // ── 拍立得卡片 ──

  Widget _buildRecordCard(DailyRecord record, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: AppStyle.cardDecoration,
        child: ClipRRect(
          borderRadius: AppStyle.borderRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 顶部：日期 + 心情 + 菜单 ──
              _buildCardHeader(record),

              // ── 中间：图片（如果有）──
              if (record.imagePath != null &&
                  record.imagePath!.isNotEmpty &&
                  File(record.imagePath!).existsSync())
                _buildCardImage(record),

              // ── 底部：文字 + 习惯 ──
              _buildCardBody(record),
            ],
          ),
        ),
      ),
    );
  }

  // ── 卡片头部：日期 + 心情 + "..."菜单 ──

  Widget _buildCardHeader(DailyRecord record) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          // 心心情色块
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.moodColors[record.mood],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(record.mood.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          // 日期
          Expanded(
            child: Text(
              _formatDate(record.date),
              style: const TextStyle(
                color: AppColors.textBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // "..." 菜单
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textMuted.withOpacity(0.6),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppColors.cardYellow,
            onSelected: (value) {
              if (value == 'edit') {
                _openCheckIn(existingRecord: record);
              } else if (value == 'delete') {
                _confirmDelete(record);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textBrown),
                    SizedBox(width: 8),
                    Text('编辑',
                        style: TextStyle(color: AppColors.textBrown)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.textBrown),
                    SizedBox(width: 8),
                    Text('删除',
                        style: TextStyle(color: AppColors.textBrown)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 卡片图片 ──

  Widget _buildCardImage(DailyRecord record) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(record.imagePath!),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 80,
              color: AppColors.bgGreen,
              child: const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: AppColors.textMuted),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── 卡片正文：文字 + 习惯标签 ──

  Widget _buildCardBody(DailyRecord record) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文字内容
          if (record.content.isNotEmpty)
            Text(
              record.content,
              style: const TextStyle(
                color: AppColors.textBrown,
                fontSize: 15,
                height: 1.5,
              ),
            ),

          // 习惯标签
          if (record.content.isNotEmpty) const SizedBox(height: 10),
          _buildHabitTags(record),
        ],
      ),
    );
  }

  // ── 习惯标签 ──

  Widget _buildHabitTags(DailyRecord record) {
    final doneHabits = DailyRecord.presetHabits
        .where((entry) => record.habits[entry.key] == true)
        .toList();

    if (doneHabits.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: doneHabits.map((entry) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.value,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textBrown),
          ),
        );
      }).toList(),
    );
  }

  // ── 删除确认弹窗 ──

  void _confirmDelete(DailyRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardYellow,
        shape:
            RoundedRectangleBorder(borderRadius: AppStyle.borderRadius),
        title: const Text(
          '删除记录',
          style: TextStyle(color: AppColors.textBrown),
        ),
        content: const Text(
          '确定要删除这条记录吗？',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _storage.deleteRecord(record.id);
              _loadRecords();
            },
            child: const Text('删除',
                style: TextStyle(color: AppColors.textBrown)),
          ),
        ],
      ),
    );
  }
}
