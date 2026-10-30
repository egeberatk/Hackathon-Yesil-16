import 'package:flutter/foundation.dart';

class BackendConfig {
  static const baseUrl = String.fromEnvironment('BACKEND_URL');

  static Uri analyzeUri(String baseUrl) {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme)) {
      throw const FormatException(
        'Backend adresi yapılandırılmamış veya geçersiz.',
      );
    }
    if (uri.scheme == 'http' && (!kDebugMode || !_isLocal(uri.host))) {
      throw const FormatException(
        'HTTP yalnızca yerel debug geliştirmesinde kullanılabilir. HTTPS adresi girin.',
      );
    }
    return uri.replace(
      path: '${uri.path.replaceFirst(RegExp(r'/+$'), '')}/analyze',
    );
  }

  static bool _isLocal(String host) {
    if (host == 'localhost' || host == '::1') return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
      return false;
    }
    return parts[0] == 10 ||
        parts[0] == 127 ||
        (parts[0] == 192 && parts[1] == 168) ||
        (parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31);
  }
}
