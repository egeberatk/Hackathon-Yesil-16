import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class PetGuideCompleteScreen extends StatefulWidget {
  const PetGuideCompleteScreen({super.key, required this.onReturnToRecipes});
  final VoidCallback onReturnToRecipes;
  @override
  State<PetGuideCompleteScreen> createState() => _PetGuideCompleteScreenState();
}

class _PetGuideCompleteScreenState extends State<PetGuideCompleteScreen> {
  bool _returning = false;
  void _return() {
    if (_returning) return;
    _returning = true;
    widget.onReturnToRecipes();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tamamlandı')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFEAF4ED),
                      child: Icon(
                        Icons.check_rounded,
                        size: 58,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(
                      'Saksın hazır!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('return-to-recipes'),
                    onPressed: _return,
                    icon: const Icon(Icons.grid_view_outlined),
                    label: const Text('Tariflere Dön'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
