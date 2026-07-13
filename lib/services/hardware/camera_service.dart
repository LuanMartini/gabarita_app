import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class CapturedProfilePhoto {
  const CapturedProfilePhoto({
    required this.path,
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String path;
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  String get dataUri {
    final type =
        mimeType == null || mimeType!.trim().isEmpty ? 'image/jpeg' : mimeType!;
    return 'data:$type;base64,${base64Encode(bytes)}';
  }

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

  Future<CapturedProfilePhoto?> captureProfilePhoto({
    double maxWidth = 360,
    double maxHeight = 360,
    int imageQuality = 70,
  }) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (image == null) return null;
    final bytes = await image.readAsBytes();

    return CapturedProfilePhoto(
      path: image.path,
      name: image.name,
      bytes: bytes,
      mimeType: image.mimeType,
    );
  }
}
