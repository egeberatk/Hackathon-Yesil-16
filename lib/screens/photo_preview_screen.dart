import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/material_item.dart';
import '../services/analysis_service.dart';
import '../services/photo_service.dart';
import '../services/recipe_repository.dart';
import '../services/material_candidate_filter.dart';
import '../widgets/analysis_photo.dart';
import '../widgets/eco_guide.dart';
import '../widgets/flow_notice.dart';
import '../widgets/page_body.dart';
import '../widgets/recipe_badge.dart';
import 'material_confirmation_screen.dart';

class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.photo,
    this.analysisService,
    this.photoService,
  });
  final XFile photo;
  final AnalysisService? analysisService;
  final PhotoService? photoService;
  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late XFile _photo = widget.photo;
  late Future<Uint8List> _bytes = _photo.readAsBytes();
  late final _photos = widget.photoService ?? PhotoService();
  final _scroll = ScrollController();
  bool _analyzing = false, _picking = false, _opening = false;
  String? _error, _selectionError;
  bool get _busy => _analyzing || _picking || _opening;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openMaterials(
    List<MaterialItem>? items, {
    String? explanation,
  }) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MaterialConfirmationScreen(
            initialItems: items,
            candidateExplanation: explanation,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _changePhoto(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _picking = true;
      _selectionError = null;
    });
    try {
      final photo = await _photos.pick(source);
      if (!mounted || photo == null) return;
      setState(() {
        _photo = photo;
        _bytes = photo.readAsBytes();
        _error = null;
      });
    } on PlatformException {
      if (mounted) {
        setState(
          () => _selectionError = 'Kamera veya galeriye erişilemedi. Cihaz ayarlarından izni kontrol edip yeniden dene.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _selectionError = 'Fotoğraf seçimi açılamadı. Başka bir seçim yöntemi deneyebilirsin.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _analyze() async {
    // Disabled controls alone cannot guard two taps in the same frame.
    if (_busy) return;
    setState(() {
      _analyzing = true;
      _error = null;
      _selectionError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _analyzing && _scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
    try {
      final items = await (widget.analysisService ?? AnalysisService()).analyze(
        _photo,
      );
      if (!mounted) return;
      final catalog = await RecipeRepository(
        bundle: DefaultAssetBundle.of(context),
      ).load();
      final selection = MaterialCandidateFilter.select(items, catalog);
      if (!mounted) return;
      setState(() => _analyzing = false);
      await _openMaterials(
        selection.candidates,
        explanation: selection.explanation,
      );
    } on AnalysisException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Analiz tamamlanamadı. Tekrar deneyebilir veya malzemelerini manuel ekleyebilirsin.',
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_analyzing && !_picking,
    child: Scaffold(
      appBar: AppBar(
        title: Text(_analyzing ? 'Analiz sürüyor' : 'Fotoğrafını kontrol et'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: _busy ? null : () => Navigator.maybePop(context),
        ),
      ),
      body: PageBody(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: RecipeBadge(
                label: '01 · Fotoğraf',
                icon: Icons.photo_camera_outlined,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _analyzing ? 'Yeni fikirler yolda.' : 'Dönüşüme ilk bakış.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            EcoGuide(
              scene: _analyzing
                  ? EcoGuideScene.analyzing
                  : _error != null
                  ? EcoGuideScene.analysisError
                  : EcoGuideScene.photo,
            ),
            const SizedBox(height: 24),
            FutureBuilder<Uint8List>(
              future: _bytes,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FlowNotice(
                        title: 'Fotoğraf açılamadı',
                        message: 'Fotoğraf okunamadı. Başka bir fotoğraf seçebilir veya yeniden çekebilirsin.',
                        warning: true,
                      ),
                      const SizedBox(height: 16),
                      _photoActions(),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnalysisPhoto(bytes: snapshot.data!, active: _analyzing),
                    const SizedBox(height: 16),
                    if (_analyzing) ...[
                      const FlowNotice(
                        title: 'Fotoğraf inceleniyor',
                        message: 'Malzemeler tespit ediliyor. Analiz yanıtı gelene kadar bu ekranı açık tut.',
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: const Text(
                          'Fotoğraf analiz ediliyor…',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      _photoActions(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: FlowNotice(
                          title: 'Analiz tamamlanamadı',
                          message: _error!,
                          warning: true,
                        ),
                      ),
                    ],
                    if (_selectionError != null) ...[
                      const SizedBox(height: 16),
                      FlowNotice(
                        title: 'Fotoğraf seçilemedi',
                        message: _selectionError!,
                        warning: true,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _analyze,
                      icon: Icon(
                        _error == null
                            ? Icons.auto_awesome_outlined
                            : Icons.refresh_outlined,
                      ),
                      label: Text(
                        _error == null ? 'Analiz Et' : 'Yeniden dene',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fotoğrafın analiz için sunucuya gönderilir. Tespitleri bir sonraki adımda sen onaylarsın.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _busy ? null : () => _openMaterials([]),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Manuel malzeme seç'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _openMaterials(null),
              child: const Text('Örnek verilerle devam et'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _photoActions() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _changePhoto(ImageSource.camera),
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Yeniden çek'),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: _busy ? null : () => _changePhoto(ImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Fotoğrafı değiştir'),
      ),
      if (_picking)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator()),
        ),
    ],
  );
}
