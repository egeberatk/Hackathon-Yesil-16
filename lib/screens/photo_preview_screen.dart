import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/material_item.dart';
import '../services/analysis_service.dart';
import '../widgets/page_body.dart';
import 'material_confirmation_screen.dart';

class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.photo,
    this.analysisService,
  });
  final XFile photo;
  final AnalysisService? analysisService;
  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late final Future<Uint8List> _bytes = widget.photo.readAsBytes();
  bool _analyzing = false;
  String? _error;

  Future<void> _openMaterials(List<MaterialItem>? items) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => MaterialConfirmationScreen(initialItems: items),
    ),
  );

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _error = null;
    });
    try {
      final items = await (widget.analysisService ?? AnalysisService()).analyze(
        widget.photo,
      );
      if (!mounted) return;
      setState(() => _analyzing = false);
      await _openMaterials(items);
    } on AnalysisException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fotoğrafını kontrol et')),
    body: PopScope(
      canPop: !_analyzing,
      child: PageBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1 / 3 · Fotoğraf'),
            const SizedBox(height: 16),
            Text(
              'Her dönüşüm bir bakışla başlar.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            FutureBuilder<Uint8List>(
              future: _bytes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Fotoğraf okunamadı. Geri dönüp başka bir fotoğraf seç.',
                  );
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        snapshot.data!,
                        height: 340,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stack) => const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'Görsel biçimi önizlenemiyor. Başka bir fotoğraf seçebilirsin.',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Analiz Et ile fotoğrafı analiz servisine gönder. Fotoğraf Gemini tarafından işlenir. Sonuçları bir sonraki adımda kontrol edip düzenleyebilirsin.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _analyzing ? null : _analyze,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Analiz Et'),
                    ),
                    if (_analyzing) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('Fotoğraf analiz ediliyor…'),
                    ],
                    if (_error != null)
                      Text(_error!, semanticsLabel: 'Analiz hatası: $_error'),
                    TextButton(
                      onPressed: _analyzing ? null : () => _openMaterials([]),
                      child: const Text('Manuel malzeme seç'),
                    ),
                    TextButton(
                      onPressed: _analyzing ? null : () => _openMaterials(null),
                      child: const Text('Örnek verilerle devam et'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _analyzing ? null : () => Navigator.pop(context),
              child: const Text('Başka fotoğraf seç'),
            ),
          ],
        ),
      ),
    ),
  );
}
