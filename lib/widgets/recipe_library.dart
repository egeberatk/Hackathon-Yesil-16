import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../core/app_theme.dart';
import 'flow_notice.dart';

import '../models/material_item.dart';
import '../models/upcycling_project.dart';
import '../services/recipe_repository.dart';
import '../services/recipe_matching_service.dart';
import 'project_card.dart';

class RecipeLibrary extends StatefulWidget {
  const RecipeLibrary({
    super.key,
    this.items,
    this.repository,
    this.horizontal = false,
    this.showAll = false,
    this.scrollable = false,
    this.header,
  });
  final bool horizontal, showAll, scrollable;
  final Widget? header;
  final List<MaterialItem>? items;
  final RecipeRepository? repository;
  @override
  State<RecipeLibrary> createState() => _RecipeLibraryState();
}

class _RecipeLibraryState extends State<RecipeLibrary> {
  late Future<List<UpcyclingProject>> _projects = _load();
  Future<List<UpcyclingProject>> _load() =>
      (widget.repository ??
              RecipeRepository(bundle: DefaultAssetBundle.of(context)))
          .load();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<UpcyclingProject>>(
    future: _projects,
    builder: (context, snapshot) {
      if (widget.scrollable) return _scrollingLibrary(context, snapshot);
      if (snapshot.hasError) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tarif kütüphanesi yüklenemedi. Lütfen tekrar dene.'),
            TextButton(
              onPressed: () => setState(() {
                _projects = _load();
              }),
              child: const Text('Tekrar dene'),
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.data!.isEmpty) {
        return const Text(
          'Onaylı tarif içerikleri henüz eklenmedi. Tarif kütüphanesi hazır olduğunda burada görünecek.',
        );
      }
      if (widget.items == null) {
        if (widget.horizontal) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth * .86).clamp(220.0, 300.0);
              return SingleChildScrollView(
                key: const Key('inspiration-scroll'),
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final project in snapshot.data!.take(6))
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: width,
                            child: ProjectCard(project: project, compact: true),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return Column(
          children: (widget.showAll ? snapshot.data! : snapshot.data!.take(2))
              .map((project) => ProjectCard(project: project))
              .toList(),
        );
      }
      final matches = RecipeMatchingService.match(
        snapshot.data!,
        widget.items!,
      );
      final available = matches.where((match) => match.canMake).toList();
      final missing = matches.where((match) => !match.canMake).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yapabilirsin',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Henüz tam eşleşen tarif yok. Aşağıda en yakın tarifleri ve eksiklerini görebilirsin.',
              ),
            ),
          ...available.map(
            (match) => ProjectCard(project: match.project, match: match),
          ),
          Text(
            'Eksik Malzemeli',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (missing.isEmpty)
            const Text('Tüm tariflerin atık malzemeleri elinde var.'),
          ...missing.map(
            (match) => ProjectCard(project: match.project, match: match),
          ),
        ],
      );
    },
  );
  Widget _scrollingLibrary(
    BuildContext context,
    AsyncSnapshot<List<UpcyclingProject>> snapshot,
  ) {
    final slivers = <Widget>[
      if (widget.header != null) SliverToBoxAdapter(child: widget.header),
    ];
    if (snapshot.hasError) {
      slivers.add(
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FlowNotice(
                title: 'Tariflere ulaşamadık',
                message: 'Tarif kütüphanesi yüklenemedi. Lütfen tekrar dene.',
                warning: true,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _projects = _load();
                }),
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    } else if (!snapshot.hasData) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    } else if (snapshot.data!.isEmpty) {
      slivers.add(
        const SliverToBoxAdapter(
          child: FlowNotice(
            title: 'Tarif kütüphanesi',
            message: 'Onaylı tarif içerikleri henüz eklenmedi. Tarif kütüphanesi hazır olduğunda burada görünecek.',
          ),
        ),
      );
    } else if (widget.items == null) {
      final projects = snapshot.data!;
      slivers.add(
        SliverList.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) => ProjectCard(
            key: ValueKey('project-card-${projects[index].id}'),
            project: projects[index],
          ),
        ),
      );
    } else {
      final matches = RecipeMatchingService.match(
        snapshot.data!,
        widget.items!,
      );
      final ready = matches.where((match) => match.canMake).toList();
      final missing = matches.where((match) => !match.canMake).toList();
      slivers.add(
        const SliverToBoxAdapter(
          child: _RecipeSection(
            key: ValueKey('ready-section'),
            title: 'Yapabilirsin',
            description: 'Atık malzemelerin yeterli. Yardımcı malzemeleri tarifte kontrol et.',
          ),
        ),
      );
      if (ready.isEmpty) {
        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: FlowNotice(
                title: 'Biraz daha malzemeyle',
                message: 'Henüz tam eşleşen tarif yok. Aşağıda en yakın tarifleri ve eksiklerini görebilirsin.',
              ),
            ),
          ),
        );
      } else {
        slivers.add(_matchList(ready));
      }
      slivers.add(
        const SliverToBoxAdapter(
          child: _RecipeSection(
            key: ValueKey('missing-section'),
            title: 'Eksik Malzemeli',
            description: 'Eksik tür ve adet sayısına göre sıralanan fikirler.',
          ),
        ),
      );
      if (missing.isEmpty) {
        slivers.add(
          const SliverToBoxAdapter(
            child: FlowNotice(
              title: 'Malzemelerin hazır',
              message: 'Tüm tariflerin atık malzemeleri elinde var.',
            ),
          ),
        );
      } else {
        slivers.add(_matchList(missing));
      }
    }
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: CustomScrollView(
            key: PageStorageKey(
              widget.items == null ? 'catalog-scroll' : 'matches-scroll',
            ),
            scrollCacheExtent: const ScrollCacheExtent.pixels(200),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(
                  AppTheme.pageInset(MediaQuery.sizeOf(context).width),
                ),
                sliver: SliverMainAxisGroup(slivers: slivers),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchList(List<RecipeMatch> matches) => SliverList.builder(
    itemCount: matches.length,
    itemBuilder: (context, index) {
      final match = matches[index];
      return ProjectCard(
        key: ValueKey('project-card-${match.project.id}'),
        project: match.project,
        match: match,
      );
    },
  );
}

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({
    super.key,
    required this.title,
    required this.description,
  });
  final String title, description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20, top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.muted),
        ),
      ],
    ),
  );
}
