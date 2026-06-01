import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_labeled_field.dart';
import '../../core/design_system/widgets/payspin_scaffold.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
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
      showPayspinSnackBar(context, 'Enter the invite code.');
      return;
    }
    setState(() => _loading = true);
    try {
      final circle = await sl<CircleRepository>().joinCircle(code);
      if (!mounted) return;
      context.go('/circles/${circle.id}');
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PayspinScaffold(
      title: 'Join Groepie',
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PayspinLabeledField(
              label: 'Invite code',
              controller: _code,
              hintText: 'ABCD1234',
              filledLetterSpacing: 4,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 32),
            PayspinGradientPillButton(label: 'Join', loading: _loading, onPressed: _loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}
