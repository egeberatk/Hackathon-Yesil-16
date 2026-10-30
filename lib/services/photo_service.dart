import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();
  Future<XFile?> pick(ImageSource source) => _picker.pickImage(
    source: source,
    maxWidth: 1800,
    maxHeight: 1800,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  Future<XFile?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final result = await _picker.retrieveLostData();
    if (result.exception != null) throw result.exception!;
    return result.files?.firstOrNull;
  }
}
