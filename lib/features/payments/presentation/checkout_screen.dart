import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/mock_payment_gateway.dart';
import '../../auth/presentation/auth_state.dart';
import '../../entities/models/order.dart' as app_models;
import '../../shared/data/app_data_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.artworkId});

  final String artworkId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gateway = MockPaymentGateway();

  int _step = 0;
  bool _submitting = false;
  String _deliveryMethod = 'Digital delivery';
  String _paymentMethod = 'GCash';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _stepValid(AuthState auth) {
    switch (_step) {
      case 0:
        return _fullNameController.text.trim().isNotEmpty &&
            (_emailController.text.trim().contains('@') ||
                auth.currentUserEmail?.contains('@') == true) &&
            _phoneController.text.trim().isNotEmpty;
      case 1:
        if (_deliveryMethod == 'Ship to address') {
          return _addressController.text.trim().isNotEmpty;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submit(AuthState auth, AppDataState data) async {
    final artwork = data.artworks
        .where((item) => item.id == widget.artworkId)
        .firstOrNull;
    if (artwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artwork could not be found.')),
      );
      return;
    }
    if (!auth.hasFirebaseSession || auth.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before completing checkout.')),
      );
      context.go('/register');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _gateway.pay(
        amount: artwork.price,
        currency: 'PHP',
        description: artwork.title,
      );
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      await data.addOrder(
        app_models.Order(
          id: orderId,
          artworkId: artwork.id,
          artworkTitle: artwork.title,
          total: artwork.price,
          buyerId: auth.currentUserId ?? '',
          buyerName: _fullNameController.text.trim(),
          artistId: artwork.artistId,
          artistName: artwork.artistName,
          paymentMethod: _paymentMethod,
          status: 'Pending',
        ),
      );
      if (!mounted) {
        return;
      }
      final title = Uri.encodeComponent(artwork.title);
      final reference = Uri.encodeComponent(result.reference);
      context.go(
        '/checkout/success?orderId=$orderId&artwork=$title&reference=$reference',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout could not be completed right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final artwork = data.artworks
        .where((item) => item.id == widget.artworkId)
        .firstOrNull;
    final formatter = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 0);

    if (_fullNameController.text.isEmpty) {
      _fullNameController.text = auth.displayName;
    }
    if (_emailController.text.isEmpty) {
      _emailController.text = auth.currentUserEmail ?? '';
    }

    if (artwork == null) {
      return const Scaffold(body: Center(child: Text('Artwork not found.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(artwork.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('by ${artwork.artistName}'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Artwork total'),
                Text(
                  formatter.format(artwork.price),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _CheckoutStepHeader(currentStep: _step),
          const SizedBox(height: 20),
          if (_step == 0) ...[
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
          ],
          if (_step == 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _deliveryMethod,
              items: const [
                DropdownMenuItem(
                  value: 'Digital delivery',
                  child: Text('Digital delivery'),
                ),
                DropdownMenuItem(
                  value: 'Ship to address',
                  child: Text('Ship to address'),
                ),
                DropdownMenuItem(
                  value: 'Meet-up arrangement',
                  child: Text('Meet-up arrangement'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _deliveryMethod = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Delivery method'),
            ),
            if (_deliveryMethod == 'Ship to address') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Delivery address',
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'This is a mock checkout flow for now. Delivery details are collected to prepare the final production flow.',
            ),
          ],
          if (_step == 2) ...[
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: const [
                DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                DropdownMenuItem(value: 'Maya', child: Text('Maya')),
                DropdownMenuItem(
                  value: 'Bank Transfer',
                  child: Text('Bank Transfer'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Payment method'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text('Buyer: ${_fullNameController.text.trim()}'),
                    Text(
                      'Contact: ${_emailController.text.trim()} · ${_phoneController.text.trim()}',
                    ),
                    Text('Delivery: $_deliveryMethod'),
                    Text('Payment: $_paymentMethod'),
                    const SizedBox(height: 8),
                    Text('Artist: ${artwork.artistName}'),
                    Text('Total: ${formatter.format(artwork.price)}'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _step -= 1),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : _step < 2
                      ? () {
                          if (!_stepValid(auth)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Complete the current step first.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _step += 1);
                        }
                      : () => _submit(auth, data),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step < 2 ? 'Continue' : 'Pay Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutStepHeader extends StatelessWidget {
  const _CheckoutStepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Contact', 'Delivery', 'Payment'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFE4D8CB),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(labels[index], style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      }),
    );
  }
}
