import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/photo_service.dart';
import '../core/app_theme.dart';
import '../widgets/workshop_artwork.dart';
import '../widgets/page_body.dart';
import '../widgets/recipe_library.dart';
import 'photo_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.photoService});
  final PhotoService? photoService;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _photos = widget.photoService ?? PhotoService();
  bool _busy = true;
  int _selectedTab = 0;
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
    MaterialPageRoute<void>(
      builder: (_) => PhotoPreviewScreen(photo: photo, photoService: _photos),
    ),
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

  Future<void> _showPicker() async {
    if (_busy) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bir fotoğrafla başla',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Malzemelerini net ve aydınlık bir yerde görüntüle.'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Fotoğraf çek'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeriden seç'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted && source != null) await _pick(source);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _selectedTab == 2 ? _catalog(context) : _home(context),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          if (index == 1) {
            _showPicker();
            return;
          }
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_outlined, color: AppTheme.primary),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            label: 'Tara',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Projeler',
          ),
        ],
      ),
    ),
  );

  Widget _brand(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.eco_outlined, color: Colors.white, size: 24),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'ReBorn AI',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.7),
        ),
      ),
      const Icon(Icons.spa_outlined, color: AppTheme.primary, size: 26),
    ],
  );

  Widget _home(BuildContext context) => PageBody(
    key: const ValueKey('home-body'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brand(context),
        const SizedBox(height: 16),
        Text(
          'ATÖLYENE HOŞ GELDİN',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(letterSpacing: 1.6, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Birlikte yeni bir hayat verelim.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 28, height: 1.2),
        ),
        const SizedBox(height: 16),
        Container(
          key: const ValueKey('scan-hero'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: .12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: (MediaQuery.sizeOf(context).width * .28).clamp(
                  88.0,
                  112.0,
                ),
                child: const ColoredBox(
                  color: Color(0xFFECF4E8),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 320,
                      height: 200,
                      child: WorkshopArtwork(hero: true),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width < 375 ? 16 : 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ne Dönüştürmek İstersin?',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bir fotoğraf çek. Elindekileri keşfet, sana uygun bir fikre dönüştür.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: const Color(0xFFD5E8DB)),
                    ),
                    const SizedBox(height: 20),
                    _heroActions(context),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          color: AppTheme.secondary,
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'İlham Al',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedTab = 2),
              child: const Text('Tümünü gör'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Küçük bir dokunuş, bambaşka bir hikâye.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 12),
        const RecipeLibrary(horizontal: true),
        const SizedBox(height: 24),
      ],
    ),
  );

  Widget _heroActions(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scan = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.secondary,
          foregroundColor: AppTheme.primary,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        onPressed: _busy ? null : _showPicker,
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Atığını Tara'),
      );
      final gallery = TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
        onPressed: _busy ? null : () => _pick(ImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined, size: 18),
        label: const Text('Galeriden seç'),
      );
      // Keep both actions readable: stack naturally on small screens or with
      // accessibility text sizes rather than fixing the card's total height.
      if (constraints.maxWidth >= 280 &&
          MediaQuery.textScalerOf(context).scale(14) <= 16.8) {
        return Row(
          children: [
            Expanded(flex: 5, child: scan),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: gallery),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [scan, const SizedBox(height: 4), gallery],
      );
    },
  );

  Widget _catalog(BuildContext context) => RecipeLibrary(
    key: const ValueKey('catalog-body'),
    showAll: true,
    scrollable: true,
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _brand(context),
        const SizedBox(height: 32),
        Text('Projeler', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Bir fikir seç, kendi dokunuşunu kat.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}
