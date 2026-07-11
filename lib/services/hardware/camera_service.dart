import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ScannedQuestionImage {
  const ScannedQuestionImage({
    required this.path,
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String path;
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'bytes_length': bytes.length,
      'mime_type': mimeType,
    };
  }
}

class CameraService {
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<ScannedQuestionImage?> scanQuestion({
    double maxWidth = 1600,
    double maxHeight = 1600,
    int imageQuality = 85,
  }) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (image == null) return null;

    return ScannedQuestionImage(
      path: image.path,
      name: image.name,
      bytes: await image.readAsBytes(),
      mimeType: image.mimeType,
    );
  }
}
