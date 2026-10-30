import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hackathon_projesi/core/backend_config.dart';
import 'package:hackathon_projesi/services/analysis_service.dart';

void main() {
  test('USB loopback adresi analyze endpointine yönlendirilir', () {
    expect(
      BackendConfig.analyzeUri('http://127.0.0.1:8000').toString(),
      'http://127.0.0.1:8000/analyze',
    );
    expect(
      BackendConfig.analyzeUri('http://localhost:8000/').toString(),
      'http://localhost:8000/analyze',
    );
    expect(
      () => BackendConfig.analyzeUri('http://example.com:8000'),
      throwsFormatException,
    );
    expect(BackendConfig.analyzeUri('https://example.com').scheme, 'https');
  });

  test(
    'Varsayılan servis derleme adresini veya USB debug varsayılanını kullanır',
    () async {
      const configured = String.fromEnvironment('BACKEND_URL');
      final expected = configured.isEmpty
          ? 'http://127.0.0.1:8000/analyze'
          : '${configured.replaceFirst(RegExp(r'/+$'), '')}/analyze';
      var requests = 0;
      final service = AnalysisService(
        clientFactory: () => MockClient((request) async {
          requests++;
          expect(request.url.toString(), expected);
          expect(request.method, 'POST');
          return http.Response('{"materials":[]}', 200);
        }),
      );
      expect(
        await service.analyze(XFile.fromData(Uint8List.fromList([1]))),
        isEmpty,
      );
      expect(requests, 1);
    },
  );

  test(
    'Açıkça boş veya hatalı adres verilirse ağ isteği gönderilmez',
    () async {
      for (final url in ['', '127.0.0.1:8000', 'not-a-url']) {
        var requests = 0;
        final service = AnalysisService(
          baseUrl: url,
          clientFactory: () => MockClient((_) async {
            requests++;
            return http.Response('{"materials":[]}', 200);
          }),
        );
        await expectLater(
          service.analyze(XFile.fromData(Uint8List(1))),
          throwsA(isA<AnalysisException>()),
        );
        expect(requests, 0);
      }
    },
  );
}
