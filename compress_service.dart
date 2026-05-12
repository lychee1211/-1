// lib/services/compress_service.dart

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CompressService {
  /// 将图片压缩到 500KB 以内，并保存到应用文档目录
  /// 返回压缩后的文件路径
  static Future<String> compressAndSave(String sourcePath) async {
    final sourceFile = File(sourcePath);
    final sourceBytes = await sourceFile.readAsBytes();

    // 如果已经小于 500KB，直接复制到应用目录
    if (sourceBytes.length <= 500 * 1024) {
      return await _copyToAppDir(sourcePath);
    }

    // 解码图片
    img.Image? original = img.decodeImage(sourceBytes);
    if (original == null) {
      return await _copyToAppDir(sourcePath);
    }

    // 如果宽高超过 1080，先缩放
    if (original.width > 1080 || original.height > 1080) {
      original = img.copyResize(
        original,
        width: original.width > original.height ? 1080 : null,
        height: original.height >= original.width ? 1080 : null,
      );
    }

    // 逐步降低质量，直到小于 500KB
    int quality = 85;
    List<int> encoded = [];

    while (quality >= 10) {
      encoded = img.encodeJpg(original, quality: quality);
      if (encoded.length <= 500 * 1024) {
        break;
      }
      quality -= 10;
    }

    // 保存到应用文档目录
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetFile = File('${appDir.path}/$fileName');
    await targetFile.writeAsBytes(encoded);

    return targetFile.path;
  }

  /// 将文件复制到应用文档目录
  static Future<String> _copyToAppDir(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = '${appDir.path}/$fileName';
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  /// 删除本地图片文件
  static Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
