import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';

/// Standard page shell: `PS.bg` background and optional app bar.
class PayspinScaffold extends StatelessWidget {
  const PayspinScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.padding,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final child = padding != null ? Padding(padding: padding!, child: body) : body;
    return Scaffold(
      backgroundColor: context.psColors.bg,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title != null
          ? AppBar(
              leading: leading,
              title: Text(title!, style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
              actions: actions,
            )
          : null,
      body: child,
    );
  }
}
