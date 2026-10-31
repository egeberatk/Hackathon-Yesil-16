import 'package:flutter/material.dart';

import '../services/recipe_photo_repository.dart';

/// Offline, curated photos only. Missing/invalid media always keeps the artwork.
class RecipeProductPhoto extends StatefulWidget {
  const RecipeProductPhoto({
    super.key,
    required this.projectId,
    required this.fallback,
    this.repository,
    this.height = 210,
  });
  final String projectId;
  final Widget fallback;
  final RecipePhotoRepository? repository;
  final double? height;
  @override
  State<RecipeProductPhoto> createState() => _RecipeProductPhotoState();
}

class _RecipeProductPhotoState extends State<RecipeProductPhoto> {
  Future<RecipePhoto?>? _photo;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo ??= _load();
  }

  Future<RecipePhoto?> _load() =>
      (widget.repository ??
              RecipePhotoRepository(bundle: DefaultAssetBundle.of(context)))
          .find(widget.projectId);
  @override
  void didUpdateWidget(covariant RecipeProductPhoto old) {
    super.didUpdateWidget(old);
    if (old.projectId != widget.projectId ||
        old.repository != widget.repository) {
      _photo = _load();
    }
  }

  void _credit(RecipePhoto photo) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                photo.aiGenerated ? 'Temsili ürün görseli' : 'Fotoğraf bilgisi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SelectableText(
                photo.aiGenerated
                    ? '${photo.title}\n\nYapay zekâ ile oluşturulmuş temsili ürün görselidir. Gerçek bir ürünün çekilmiş fotoğrafı değildir.'
                    : '${photo.title}\n${photo.author}\n${photo.license}\n${photo.sourceUrl}\n${photo.licenseUrl}\nEkrana sığdırmak için kırpılmış olabilir.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('product-photo-area'),
    height: widget.height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: FutureBuilder<RecipePhoto?>(
        future: _photo,
        builder: (context, snapshot) {
          final photo = snapshot.data;
          if (photo == null) return widget.fallback;
          return Image.asset(
            photo.asset,
            key: const Key('recipe-product-image'),
            fit: photo.aiGenerated ? BoxFit.contain : BoxFit.cover,
            width: double.infinity,
            height: widget.height,
            cacheWidth:
                (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .round()
                    .clamp(256, 1024),
            semanticLabel: photo.aiGenerated
                ? '${photo.title}, yapay zekâ ile oluşturulmuş temsili görsel'
                : photo.title,
            errorBuilder: (_, _, _) => widget.fallback,
            frameBuilder: (context, image, frame, sync) => frame == null
                ? widget.fallback
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: const Color(0xFFF5F2EC), child: image),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: IconButton.filledTonal(
                          onPressed: () => _credit(photo),
                          tooltip: photo.aiGenerated
                              ? 'AI görseli'
                              : 'Fotoğraf bilgisi',
                          icon: photo.aiGenerated
                              ? const Text(
                                  'AI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : const Icon(Icons.info_outline),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    ),
  );
}
