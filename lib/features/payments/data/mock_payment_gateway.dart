import 'dart:async';

class MockPaymentResult {
  const MockPaymentResult({
    required this.reference,
    required this.success,
    required this.message,
  });

  final String reference;
  final bool success;
  final String message;
}

class MockPaymentGateway {
  Future<MockPaymentResult> pay({
    required double amount,
    required String currency,
    required String description,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final reference = 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
    return MockPaymentResult(
      reference: reference,
      success: true,
      message:
          'Mock payment approved for $currency ${amount.toStringAsFixed(0)}',
    );
  }
}
