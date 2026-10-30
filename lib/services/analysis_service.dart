import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/backend_config.dart';
import '../models/material_item.dart';

class AnalysisException implements Exception {
  const AnalysisException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AnalysisService {
  AnalysisService({
    this.baseUrl = BackendConfig.baseUrl,
    http.Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? http.Client.new;
  final String baseUrl;
  final http.Client Function() _clientFactory;

  Future<List<MaterialItem>> analyze(XFile photo) async {
    final client = _clientFactory();
    try {
      final uri = BackendConfig.analyzeUri(baseUrl);
      if (await photo.length() > 8 * 1024 * 1024) {
        throw const AnalysisException(
          'Fotoğraf en fazla 8 MB olabilir. Daha küçük bir fotoğraf seç.',
        );
      }
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            await photo.readAsBytes(),
            filename: 'photo.jpg',
          ),
        );
      final response = await (() async {
        final stream = await client.send(request);
        return http.Response.fromStream(stream);
      })().timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        String? message;
        try {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          if (body is Map &&
              body['error'] is Map &&
              body['error']['message'] is String) {
            message = body['error']['message'] as String;
          }
        } on FormatException {
          /* Genel hata mesajı kullanılır. */
        }
        throw AnalysisException(
          message ??
              'Analiz tamamlanamadı. Tekrar dene veya manuel giriş kullan.',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic> ||
          body['materials'] is! List ||
          (body['materials'] as List).length > 50) {
        throw const FormatException('Geçersiz analiz yanıtı.');
      }
      return (body['materials'] as List).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Geçersiz malzeme.');
        }
        return MaterialItem.fromJson(item);
      }).toList();
    } on AnalysisException {
      rethrow;
    } on TimeoutException {
      throw const AnalysisException(
        'Analiz zaman aşımına uğradı. Tekrar dene veya manuel giriş kullan.',
      );
    } on FormatException catch (error) {
      throw AnalysisException(
        'Analiz yapılandırması veya yanıtı geçersiz: ${error.message}',
      );
    } catch (_) {
      throw const AnalysisException(
        'Backend bağlantısı kurulamadı. Sunucunun çalıştığını ve bağlantı ayarlarını kontrol et veya manuel giriş kullan.',
      );
    } finally {
      client.close();
    }
  }
}
