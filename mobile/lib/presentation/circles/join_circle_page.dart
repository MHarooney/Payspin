import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/repositories/circle_repository.dart';

class JoinCirclePage extends StatefulWidget {
  const JoinCirclePage({super.key});

  @override
  State<JoinCirclePage> createState() => _JoinCirclePageState();
}

class _JoinCirclePageState extends State<JoinCirclePage> {
  final _code = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the invite code.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final circle = await sl<CircleRepository>().joinCircle(code);
      if (!mounted) return;
      context.go('/circles/${circle.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Join Groepie', style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Invite code', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w700, color: PayspinTokens.mint, letterSpacing: 4),
            ),
            const SizedBox(height: 32),
            PayspinGradientPillButton(label: 'Join', loading: _loading, onPressed: _loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}
