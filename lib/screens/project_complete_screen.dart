import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../animations/eco_mascot_motion.dart';
import '../core/app_theme.dart';
import '../core/eco_guide_messages.dart';
import '../widgets/eco_guide.dart';
import '../widgets/eco_mascot_avatar.dart';
import 'home_screen.dart';

/// All recipes finish here, with no completed-project routes left underneath.
class ProjectCompleteScreen extends StatefulWidget {
  const ProjectCompleteScreen({super.key});

  @override
  State<ProjectCompleteScreen> createState() => _ProjectCompleteScreenState();
}

class _ProjectCompleteScreenState extends State<ProjectCompleteScreen> {
  static const _cream = Color(0xFFF7F7EF);
  bool _returning = false;

  void _returnHome() {
    if (_returning) return;
    _returning = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/'),
        builder: (_) => const HomeScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _returnHome();
    },
    child: Scaffold(
      backgroundColor: _cream,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: FilledButton.icon(
          key: const Key('return-to-home'),
          onPressed: _returnHome,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Ana Menüye Dön'),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final inset = AppTheme.pageInset(constraints.maxWidth);
            final availableWidth = math.min(
              480.0,
              constraints.maxWidth - inset * 2,
            );
            final figureSize = math.min(
              availableWidth,
              (constraints.maxHeight * .5).clamp(160.0, 420.0),
            );
            return SingleChildScrollView(
              key: const Key('completion-scroll'),
              padding: EdgeInsets.fromLTRB(inset, 8, inset, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        header: true,
                        child: Text(
                          'Harika İş Çıkardın! 🌱',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.primary,
                                fontFamilyFallback: const [
                                  'Noto Color Emoji',
                                  'Segoe UI Emoji',
                                ],
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bir malzemeye yeni bir kullanım alanı kazandırdın.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: EcoMascotAvatar(
                          key: const Key('completion-mascot'),
                          mood: EcoMascotMood.celebrating,
                          size: figureSize,
                        ),
                      ),
                      const SizedBox(height: 16),
                      EcoSpeechBubble(
                        key: const Key('completion-message'),
                        message: EcoGuideMessages.text(EcoGuideScene.completed),
                        tailAbove: true,
                        padding: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
