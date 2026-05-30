import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/repositories/circle_repository.dart';

class CreateCirclePage extends StatefulWidget {
  const CreateCirclePage({super.key});

  @override
  State<CreateCirclePage> createState() => _CreateCirclePageState();
}

class _CreateCirclePageState extends State<CreateCirclePage> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _members = TextEditingController(text: '3');
  final _cycleDays = TextEditingController(text: '30');
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _members.dispose();
    _cycleDays.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final euros = double.tryParse(_amount.text.replaceAll(',', '.'));
    final members = int.tryParse(_members.text);
    final days = int.tryParse(_cycleDays.text);
    if (name.length < 2 || euros == null || euros <= 0 || members == null || members < 2 || days == null || days < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check name, amount, members (≥2), and cycle (≥7 days).')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final circle = await sl<CircleRepository>().createCircle(
        name: name,
        contributionCents: (euros * 100).round(),
        cycleDurationDays: days,
        memberCount: members,
      );
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
        title: Text('Create Groepie', style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Name', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
          TextField(controller: _name, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          Text('Contribution (EUR)', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
          TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          Text('Members', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
          TextField(controller: _members, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          Text('Cycle (days)', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
          TextField(controller: _cycleDays, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 32),
          PayspinGradientPillButton(label: 'Create', loading: _loading, onPressed: _loading ? null : _submit),
        ],
      ),
    );
  }
}
