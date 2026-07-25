// lib/screens/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/providers/order_provider.dart';

import 'orders_screen.dart' show formatBookingDate, formatBookingTime;

class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orderProvider.notifier).getOrderDetail(widget.orderId));
  }

  @override
  void dispose() {
    // ✅ FIX: dispose() नंतर `ref` वापरणं क्रॅश देत होतं (widget आधीच
    // disposed असतो). notifier ला थेट, widget lifecycle बाहेर वेगळं
    // capture करून वापरतोय — Future.microtask च्या आत `ref` touch करत नाही.
    final notifier = ref.read(orderProvider.notifier);
    Future.microtask(() => notifier.clearSelectedOrder());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final order = orderState.selectedOrder;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: orderState.isLoading || order == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Order Info',
              children: [
                _InfoRow('Order Number', order['order_number']?.toString() ?? ''),
                _InfoRow('Status', order['status']?.toString() ?? ''),
                _InfoRow('Payment Status', order['payment_status']?.toString() ?? ''),
                _InfoRow('Booking Date', formatBookingDate(order['booking_date']?.toString())),
                _InfoRow('Booking Time', formatBookingTime(order['booking_time']?.toString())),
              ],
            ),
            const SizedBox(height: 16),
            // ✅ FIX: actual JSON key `shipping_address` आहे, `address`
            // नाही — त्यामुळे हे section आधी कधीच दिसत नव्हतं.
            if (order['shipping_address'] != null)
              _SectionCard(
                title: 'Shipping Address',
                children: [
                  _InfoRow('Name', '${order['shipping_address']['first_name'] ?? ''} ${order['shipping_address']['last_name'] ?? ''}'),
                  _InfoRow('Address', order['shipping_address']['address']?.toString() ?? ''),
                  _InfoRow('City', order['shipping_address']['city']?.toString() ?? ''),
                  _InfoRow('Mobile', order['shipping_address']['mobile']?.toString() ?? ''),
                ],
              ),
            const SizedBox(height: 16),
            if (order['items'] != null)
              _SectionCard(
                title: 'Items',
                children: (order['items'] as List? ?? []).map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['name']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₹${item['price'] ?? 0}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Payment Summary',
              children: [
                _InfoRow('Subtotal', '₹${order['subtotal'] ?? 0}'),
                _InfoRow('Discount', '₹${order['discount'] ?? 0}'),
                // ✅ FIX: actual field नाव `shipping` आहे (shipping_charge
                // किंवा commuting_charge नाही).
                _InfoRow('Commuting Charge', '₹${order['shipping'] ?? 0}'),
                _InfoRow('Grand Total', '₹${order['grand_total'] ?? 0}', isBold: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool isBold;

  const _InfoRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? AppColors.primary : AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}