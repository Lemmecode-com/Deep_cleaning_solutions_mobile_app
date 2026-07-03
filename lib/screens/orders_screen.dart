import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/providers/order_provider.dart';

import '../providers/auth_provider.dart';

// ✅ ISO datetime ("2026-07-03T00:00:00.000000Z") → readable "03 Jul 2026"
// कुठलंही package न वापरता — parse fail झालं तर raw value जशीच्या तशी दाखवतो
// (crash नाही, silent fallback).
String formatBookingDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final date = DateTime.parse(raw).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return raw;
  }
}

// ✅ "13:00:00" → "1:00 PM". फक्त HH:mm:ss किंवा HH:mm पॅटर्न असेल तरच फॉरमॅट
// करतो, नाहीतर raw value दाखवतो.
String formatBookingTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final parts = raw.split(':');
  if (parts.length < 2) return raw;

  final hour24 = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour24 == null || minute == null) return raw;

  final period = hour24 >= 12 ? 'PM' : 'AM';
  int hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  final minuteStr = minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr $period';
}

class OrdersScreen extends ConsumerStatefulWidget {
  final bool embedded; // ✅ true = bottom nav tab, false = pushed route

  const OrdersScreen({super.key, this.embedded = false});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.isLoggedIn) {        // ✅ Only fetch orders if logged in
        ref.read(orderProvider.notifier).getOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final orderState = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        // ✅ Tab म्हणून उघडली असेल तर back button नकोच — bottom nav आधीच navigation देतो
        leading: widget.embedded
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: !authState.isLoggedIn
          ? _GuestOrdersPrompt()
          : orderState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : orderState.orders.isEmpty
          ? _EmptyOrders()
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(orderProvider.notifier).getOrders(),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orderState.orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final order = orderState.orders[i];
            return _OrderCard(
              order: order,
              onTap: () => context.push('/orders/${order['id']}'),
            );
          },
        ),
      ),
    );
  }
}

// ✅ Shown when a guest user opens the Orders tab
class _GuestOrdersPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Login to view your orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to track and manage your bookings',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Login / Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 80),
            const SizedBox(height: 16),
            const Text(
              'No orders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your booked services will appear here',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Book a Service'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return AppColors.green;
      case 'pending':
        return AppColors.secondary;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String orderNumber   = order['order_number']?.toString() ?? '';
    final String status        = order['status']?.toString() ?? 'Pending';
    final String paymentStatus = order['payment_status']?.toString() ?? '';
    final String grandTotal    = order['grand_total']?.toString() ?? '0';
    // ✅ readable format
    final String bookingDate   = formatBookingDate(order['booking_date']?.toString());
    final String bookingTime   = formatBookingTime(order['booking_time']?.toString());
    final int itemsCount       = order['items_count'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.black),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '$bookingDate • $bookingTime',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '$itemsCount item(s)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment: $paymentStatus',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '₹$grandTotal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}