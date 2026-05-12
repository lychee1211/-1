// lib/widgets/check_in_sheet.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/daily_record.dart';
import '../services/storage_service.dart';
import '../services/image_service.dart';
import '../services/compress_service.dart';
import '../pages/doodle_page.dart';

class CheckInSheet extends StatefulWidget {
  final DailyRecord? existingRecord;
  final VoidCallback onSaved;

  const CheckInSheet({
    super.key,
    this.existingRecord,
    required this.onSaved,
  });

  @override
  State<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<CheckInSheet> {
  late MoodType _selectedMood;
  late Map<String, bool> _habits;
  late TextEditingController _contentController;
  String? _imagePath;

  final _storage = StorageService();
  final _imageService = ImageService();

  bool get _isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRecord;
    _selectedMood = existing?.mood ?? MoodType.calm;
    _habits = Map<String, bool>.from(
      existing?.habits ??
          {
            'drink_water': false,
            'sleep_early': false,
            'exercise': false,
          },
    );
    _contentController = TextEditingController(text: existing?.content ?? '');

    // 检查已有图片是否还存在
    final savedPath = existing?.imagePath;
    if (savedPath != null &&
        savedPath.isNotEmpty &&
        File(savedPath).existsSync()) {
      _imagePath = savedPath;
    } else {
      _imagePath = null;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // ── 保存记录 ──────────────────────────

  Future<void> _save() async {
    final now = DateTime.now();
    final id = _isEditing
        ? widget.existingRecord!.id
        : '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final date = _isEditing ? widget.existingRecord!.date : now;

    // 如果有图片且路径变了，压缩保存
    String? finalImagePath;
    if (_imagePath != null) {
      // 如果是编辑模式且图片没变，保留原路径
      if (_isEditing && _imagePath == widget.existingRecord!.imagePath) {
        finalImagePath = _imagePath;
      } else {
        finalImagePath = await CompressService.compressAndSave(_imagePath!);
      }
    }

    final record = DailyRecord(
      id: id,
      date: date,
      mood: _selectedMood,
      habits: _habits,
      content: _contentController.text.trim(),
      imagePath: finalImagePath,
    );

    await _storage.saveRecord(record);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
    }
  }

  // ── 选择图片 ──────────────────────────

  Future<void> _pickImage() async {
    final file = await _imageService.pickAndCropImage(context);
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  // ── 打开涂鸦 ──────────────────────────

  Future<void> _openDoodle() async {
    if (_imagePath == null) return;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => DoodlePage(imagePath: _imagePath!),
      ),
    );

    if (result != null) {
      setState(() => _imagePath = result);
    }
  }

  // ── 构建 UI ──────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.67,
        decoration: BoxDecoration(
          color: AppColors.glassOverlay,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardYellow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding:
                EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 顶部拖拽条 ──
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 标题 ──
                Text(
                  _isEditing ? '编辑记录' : '今日签到',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 24),

                // ── 心情选择器 ──
                _buildSectionTitle('今天心情如何？'),
                const SizedBox(height: 12),
                _buildMoodSelector(),
                const SizedBox(height: 28),

                // ── 习惯打卡 ──
                _buildSectionTitle('打卡一下'),
                const SizedBox(height: 12),
                _buildHabitChips(),
                const SizedBox(height: 28),

                // ── 图文输入 ──
                _buildSectionTitle('记录一下'),
                const SizedBox(height: 12),
                _buildImageArea(),
                const SizedBox(height: 12),
                _buildTextField(),
                const SizedBox(height: 32),

                // ── 保存按钮 ──
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 段落标题 ──

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textBrown,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── 心情选择器 ──

  Widget _buildMoodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: MoodType.values.map((mood) {
        final isSelected = _selectedMood == mood;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedMood = mood);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.moodColors[mood]
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    mood.emoji,
                    style: TextStyle(
                      fontSize: 32,
                      color: isSelected
                          ? null
                          : Colors.black.withOpacity(0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? AppColors.textBrown
                        : AppColors.textMuted,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 习惯打卡 ──

  Widget _buildHabitChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: DailyRecord.presetHabits.map((entry) {
        final isDone = _habits[entry.key] ?? false;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _habits[entry.key] = !isDone);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.moodColors[MoodType.calm]
                  : AppColors.bgGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDone
                    ? AppColors.textBrown.withOpacity(0.15)
                    : AppColors.textMuted.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.value,
                  style: const TextStyle(fontSize: 14),
                ),
                if (isDone) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.textBrown.withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── 图片区域 ──

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: _imagePath != null
          ? _buildImagePreview()
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _openDoodle,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(File(_imagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // 右上角删除
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _imagePath = null),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // 左下角涂鸦
        Positioned(
          bottom: 8,
          left: 8,
          child: GestureDetector(
            onTap: _openDoodle,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined,
                      size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '涂鸦',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.bgGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textMuted.withOpacity(0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            '添加图片',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── 文字输入 ──

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: 4,
        minLines: 2,
        style: const TextStyle(
          color: AppColors.textBrown,
          fontSize: 15,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: '今天有什么开心的事？',
          hintStyle: TextStyle(
            color: AppColors.textMuted.withOpacity(0.5),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ── 保存按钮 ──

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textBrown,
          foregroundColor: AppColors.cardYellow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyle.borderRadius,
          ),
        ),
        child: Text(
          _isEditing ? '保存修改' : '记录今天',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
