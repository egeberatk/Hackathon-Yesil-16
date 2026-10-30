import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/photo_service.dart';
import '../services/demo_data_service.dart';
import '../widgets/page_body.dart';
import '../widgets/project_card.dart';
import 'photo_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _photos = PhotoService();
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recover());
  }

  Future<void> _recover() async {
    try {
      final photo = await _photos.recover();
      if (mounted && photo != null) await _open(photo);
    } catch (_) {
      if (mounted) {
        _message('Önceki fotoğraf kurtarılamadı. Lütfen yeniden seç.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  Future<void> _open(XFile photo) => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => PhotoPreviewScreen(photo: photo)),
  );
  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final photo = await _photos.pick(source);
      if (mounted && photo != null) await _open(photo);
    } on PlatformException {
      if (mounted) {
        _message(
          'Fotoğrafa erişilemedi. Kamera veya galeri iznini cihaz ayarlarından kontrol edip tekrar dene.',
        );
      }
    } catch (_) {
      if (mounted) {
        _message(
          'Bu cihazda fotoğraf seçimi açılamadı. Galeriden seçmeyi deneyebilirsin.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('ReBorn AI'),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 24),
          child: Icon(Icons.eco_outlined),
        ),
      ],
    ),
    body: PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip(
            avatar: Icon(Icons.auto_awesome, size: 18),
            label: Text('Az atık, çok fikir'),
          ),
          const SizedBox(height: 24),
          Text(
            'Bir son değil,\nyeni bir başlangıç.',
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Evindeki atıl malzemeleri yaratıcı projelere dönüştür. Bir fotoğrafla ilk adımı at.',
            style: TextStyle(fontSize: 17, height: 1.5),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const Icon(Icons.recycling_rounded, size: 76),
                const SizedBox(height: 16),
                Text(
                  'Dönüşüm seninle başlar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Malzemelerini birlikte keşfedelim.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Fotoğraf çek'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeriden seç'),
                  ),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fotoğrafını analiz et veya manuel giriş kullan. İlham projeleri ve tarifler örnek veridir.',
          ),
          const SizedBox(height: 32),
          Text('Nasıl çalışır?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text(
            '01  Fotoğrafını seç\n02  Malzemelerini düzenle ve onayla\n03  Bir proje seç, dönüşüme başla',
            style: TextStyle(height: 2),
          ),
          const SizedBox(height: 32),
          Text('Biraz ilham', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Küçük dokunuşlar, yeni hikâyeler.'),
          const SizedBox(height: 20),
          ...DemoDataService.projects
              .take(2)
              .map((project) => ProjectCard(project: project)),
        ],
      ),
    ),
  );
}
