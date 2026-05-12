// lib/services/image_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../main.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickAndCropImage(BuildContext context) async {
    // Windows 桌面端暂不支持图片选择，在手机上测试
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('图片功能请在手机上测试～'),
            backgroundColor: AppColors.textBrown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return null;
    }

    // 手机端弹出选择来源
    final source = await _showSourceDialog(context);
    if (source == null) return null;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (picked == null) return null;

    // 裁剪
    final cropped = await _cropImage(picked.path);
    if (cropped == null) return null;

    return File(cropped.path);
  }

  /// 底部弹窗选择来源
  Future<ImageSource?> _showSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardYellow,
            borderRadius: AppStyle.borderRadius,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSourceOption(
                  ctx,
                  icon: Icons.photo_library_outlined,
                  label: '从相册选择',
                  source: ImageSource.gallery,
                ),
                const Divider(height: 1, indent: 24, endIndent: 24),
                _buildSourceOption(
                  ctx,
                  icon: Icons.camera_alt_outlined,
                  label: '拍照',
                  source: ImageSource.camera,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textBrown),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textBrown,
          fontSize: 16,
        ),
      ),
      onTap: () => Navigator.pop(ctx, source),
    );
  }

  /// 裁剪图片
  Future<CroppedFile?> _cropImage(String filePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪图片',
          toolbarColor: AppColors.textBrown,
          toolbarWidgetColor: AppColors.cardYellow,
          backgroundColor: AppColors.bgGreen,
          activeControlsWidgetColor: AppColors.textBrown,
          cropFrameColor: AppColors.textBrown,
          cropGridColor: AppColors.textMuted.withOpacity(0.3),
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
          ],
        ),
        IOSUiSettings(
          title: '裁剪图片',
          aspectRatioLockEnabled: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
          ],
        ),
      ],
    );
    return cropped;
  }
}
