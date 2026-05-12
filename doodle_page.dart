// lib/pages/doodle_page.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';

class DoodlePage extends StatefulWidget {
  /// 原始图片文件路径
  final String imagePath;

  const DoodlePage({super.key, required this.imagePath});

  @override
  State<DoodlePage> createState() => _DoodlePageState();
}

class _DoodlePageState extends State<DoodlePage> {
  // 涂鸦笔迹列表
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // 画笔颜色和粗细
  Color _penColor = AppColors.textBrown;
  double _penWidth = 4.0;

  // 可选画笔颜色
  final List<Color> _colors = [
    AppColors.textBrown,
    Colors.black87,
    const Color(0xFFE57373), // 红
    const Color(0xFF81C784), // 绿
    const Color(0xFF64B5F6), // 蓝
    const Color(0xFFFFB74D), // 橙
    Colors.white,
  ];

  // 用于截图导出
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      appBar: AppBar(
        backgroundColor: AppColors.bgGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '涂鸦',
          style: TextStyle(
            color: AppColors.textBrown,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // 撤销按钮
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: AppColors.textBrown),
            onPressed: () {
              if (_strokes.isNotEmpty) {
                setState(() => _strokes.removeLast());
              }
            },
          ),
          // 保存按钮
          TextButton(
            onPressed: _saveDoodle,
            child: const Text(
              '保存',
              style: TextStyle(
                color: AppColors.textBrown,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 画布区域 ──
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // 底层：原始图片
                      Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // 上层：涂鸦画布
                      Positioned.fill(
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            painter: _DoodlePainter(
                              strokes: _strokes,
                              currentStroke: _currentStroke,
                              penColor: _penColor,
                              penWidth: _penWidth,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 底部工具栏 ──
          _buildToolbar(),
        ],
      ),
    );
  }

  // ── 手势处理 ──────────────────────────

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _strokes.add(List.from(_currentStroke));
      }
      _currentStroke = [];
    });
  }

  // ── 保存涂鸦结果 ──────────────────────────

  Future<void> _saveDoodle() async {
    try {
      // 截取 RepaintBoundary 区域为图片
      final boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      // 保存到临时目录
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'doodle_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        Navigator.pop(context, file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.textBrown,
          ),
        );
      }
    }
  }

  // ── 底部工具栏 ──────────────────────────

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.cardYellow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 颜色选择
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _colors.map((color) {
              final isSelected = _penColor == color;
              return GestureDetector(
                onTap: () => setState(() => _penColor = color),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textBrown
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // 粗细滑块
          Row(
            children: [
              const Text(
                '细',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _penWidth,
                  min: 1.0,
                  max: 12.0,
                  activeColor: AppColors.textBrown,
                  inactiveColor: AppColors.bgGreen,
                  onChanged: (v) => setState(() => _penWidth = v),
                ),
              ),
              const Text(
                '粗',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 涂鸦画笔 Painter
// ═══════════════════════════════════════════

class _DoodlePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color penColor;
  final double penWidth;

  _DoodlePainter({
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.penWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制已完成的笔迹
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, penColor, penWidth);
    }
    // 绘制当前正在画的笔迹
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, penColor, penWidth);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.length < 2) {
      // 只有一个点，画一个小圆点
      final paint = Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(points.first, width / 2, paint);
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      // 用二次贝塞尔曲线让笔迹更平滑
      final p0 = points[i - 1];
      final p1 = points[i];
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }

    // 连到最后一个点
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}
