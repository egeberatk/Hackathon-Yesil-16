import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.controller});
  final Widget child;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.all(
            AppTheme.pageInset(MediaQuery.sizeOf(context).width),
          ),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    ),
  );
}
