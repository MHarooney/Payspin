import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/payment_link.dart';

/// Launches a prefilled send-name flow to create a new link from a closed one.
abstract final class RequestAgainFlow {
  static void launch(BuildContext context, PaymentLink link) {
    context.push('/send/name', extra: {
      'cents': link.amountCents,
      'amountLabel': link.amountLabel,
      'initialDescription': link.description ?? '',
    });
  }
}
