import 'dart:io';

Future<int> getLocalFileSizeBytes(String path) async {
  try {
    return await File(path).length();
  } catch (_) {
    return 0;
  }
}
