import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/di/injection.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_labeled_field.dart';
import '../../core/design_system/widgets/payspin_scaffold.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
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
    if (name.length < 2 ||
        euros == null ||
        euros <= 0 ||
        members == null ||
        members < 2 ||
        days == null ||
        days < 7) {
      showPayspinSnackBar(context, 'Check name, amount, members (≥2), and cycle (≥7 days).');
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
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PayspinScaffold(
      title: 'Create Groepie',
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PayspinLabeledField(
            label: 'Name',
            controller: _name,
            hintText: 'Weekend trip',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          PayspinLabeledField(
            label: 'Contribution (EUR)',
            controller: _amount,
            hintText: '25.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          ),
          const SizedBox(height: 20),
          PayspinLabeledField(
            label: 'Members',
            controller: _members,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          PayspinLabeledField(
            label: 'Cycle (days)',
            controller: _cycleDays,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 32),
          PayspinGradientPillButton(label: 'Create', loading: _loading, onPressed: _loading ? null : _submit),
        ],
      ),
    );
  }
}
