import 'dart:ui'; // ✅ NEW: for ImageFilter.blur on unpriced amounts
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dcs_app/utils/app_colors.dart';
import 'package:dcs_app/utils/app_images.dart';
import 'package:dcs_app/utils/responsive.dart';
import 'package:dcs_app/providers/cart_provider.dart';
import 'package:dcs_app/providers/order_provider.dart'; // ✅ NEW: reuse branches list
import 'package:dcs_app/widgets/app_network_image.dart';

// ✅ NEW: shows a price Text, blurred out until a city is selected.
// Once hasBranchSelected is true, the price animates into view clearly.
// While blurred, it's tappable — tapping opens the city picker so the
// user immediately understands *why* it's blurred and how to fix it.
class _BlurredAmount extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool blurred;
  final VoidCallback? onTap;
  final MainAxisAlignment alignment;

  const _BlurredAmount({
    required this.text,
    required this.style,
    required this.blurred,
    this.onTap,
    this.alignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    final clearChild = Text(text, style: style);

    final blurredChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Icon(Icons.lock_outline_rounded, size: (style.fontSize ?? 14) * 0.85, color: AppColors.textMuted),
        const SizedBox(width: 4),
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Text(text, style: style),
        ),
      ],
    );

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey(blurred),
        child: blurred ? blurredChild : clearChild,
      ),
    );

    if (!blurred || onTap == null) return content;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: content);
  }
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cartProvider.notifier).getCart();
      if (ref.read(orderProvider).branches.isEmpty) {
        ref.read(orderProvider.notifier).getCheckoutInit(branchId: 1);
      }
    });
  }

  // ✅ FIX: `as int` unsafe cast काढला. आता `as int?` वापरतोय — जर backend
  // ने कधी id null/string पाठवली तर तो specific city entry silently
  // वगळला जातो (SizedBox.shrink), संपूर्ण picker क्रॅश होत नाही. Valid
  // data (जे normally असतंच) असताना behavior आधीसारखंच राहते.
  void _openCityPicker() {
    final branches = ref.read(orderProvider).branches;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select your city', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: branches.length,
                  itemBuilder: (_, i) {
                    final b = branches[i];
                    final id    = b['id'] as int?;
                    final city  = b['city']?.toString() ?? '';
                    final state = b['state']?.toString() ?? '';
                    if (id == null) return const SizedBox.shrink();
                    final selected = ref.read(cartProvider).selectedBranchId == id;
                    return ListTile(
                      title: Text(state.isNotEmpty ? '$city, $state' : city),
                      trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final ok = await ref.read(cartProvider.notifier).setBranch(id);
                        if (!ok && mounted) {
                          final err = ref.read(cartProvider).branchError ?? 'Could not select city';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: AppColors.secondary),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState  = ref.watch(cartProvider);
    final orderState = ref.watch(orderProvider);
    final cartItems  = cartState.cartItems;

    String? selectedCityLabel;
    if (cartState.selectedBranchId != null) {
      final match = orderState.branches.firstWhere(
            (b) => b['id'] == cartState.selectedBranchId,
        orElse: () => const {},
      );
      selectedCityLabel = match['city']?.toString();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: cartState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : cartItems.isEmpty
          ? _EmptyCart()
          : Column(
        children: [
          _CityBanner(
            cityLabel: selectedCityLabel,
            isLoading: cartState.isBranchLoading,
            onTap: _openCityPicker,
          ),

          if (cartState.unavailableInBranch.isNotEmpty)
            _UnavailableBanner(items: cartState.unavailableInBranch, cityLabel: selectedCityLabel),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(cartProvider.notifier).getCart(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final rowId = cartItems[i]['rowId']?.toString() ?? '';
                  return _CartItemCard(
                    item: cartItems[i],
                    branchPrice: cartState.hasBranchSelected
                        ? ref.read(cartProvider.notifier).finalPriceFor(rowId)
                        : null,
                    isUnavailableInBranch: cartState.hasBranchSelected &&
                        ref.read(cartProvider.notifier).isUnavailableInBranch(rowId),
                    hasBranchSelected: cartState.hasBranchSelected,
                    onSelectCity: _openCityPicker,
                    onRemove: () => ref.read(cartProvider.notifier).removeCartItem(rowId),
                  );
                },
              ),
            ),
          ),
          _CartSummary(
            totalAmount: cartState.totalAmount,
            discountAmount: cartState.discountAmount,
            finalAmount: cartState.finalAmount,
            hasBranchSelected: cartState.hasBranchSelected,
            hasUnavailableItems: cartState.unavailableInBranch.isNotEmpty,
            onSelectCity: _openCityPicker,
            onCheckout: () {
              if (!cartState.hasBranchSelected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select your city before checkout'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
                _openCityPicker();
                return;
              }
              if (cartState.unavailableInBranch.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please remove items unavailable in this city to continue'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
                return;
              }
              context.go('/checkout');
            },
          ),
        ],
      ),
    );
  }
}

class _CityBanner extends StatelessWidget {
  final String? cityLabel;
  final bool isLoading;
  final VoidCallback onTap;

  const _CityBanner({required this.cityLabel, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCity = cityLabel != null && cityLabel!.isNotEmpty;

    final Color accent = hasCity ? AppColors.primary : AppColors.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasCity
                    ? [AppColors.primary.withOpacity(0.10), AppColors.primary.withOpacity(0.04)]
                    : [AppColors.secondary.withOpacity(0.16), AppColors.secondary.withOpacity(0.06)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(hasCity ? 0.35 : 0.55), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(hasCity ? 0.14 : 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isLoading
                        ? 'Updating prices...'
                        : hasCity
                        ? 'Showing prices for $cityLabel'
                        : 'Select your city to see accurate pricing',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasCity ? 'Change' : 'Select',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  final List<dynamic> items;
  final String? cityLabel;
  const _UnavailableBanner({required this.items, this.cityLabel});

  @override
  Widget build(BuildContext context) {
    final city = (cityLabel != null && cityLabel!.isNotEmpty) ? cityLabel! : 'the selected city';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.secondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Service Unavailable in Selected City',
                  style: TextStyle(fontSize: 13, color: AppColors.secondary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((e) {
            final name = e['name']?.toString() ?? 'This service';
            return Padding(
              padding: const EdgeInsets.only(left: 26, bottom: 2),
              child: Text(
                '•  $name in $city is not available in the selected city.',
                style: const TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600, height: 1.35),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, color: AppColors.textMuted, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add services to get started',
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
              child: const Text('Shop Now'),
            ),
          ],
        ),
      ),
    );
  }
}

String _getImageForService(String serviceName) {
  final name = serviceName.toLowerCase();

  int bhkIndex = 0;
  if (name.contains('2 bhk') || name.contains('2bhk')) bhkIndex = 1;
  else if (name.contains('3 bhk') || name.contains('3bhk')) bhkIndex = 2;
  else if (name.contains('4 bhk') || name.contains('4bhk')) bhkIndex = 3;
  else if (name.contains('5 bhk') || name.contains('5bhk')) bhkIndex = 4;

  if (name.contains('unfurnished')) {
    return AppImages.unfurnishedBHK[bhkIndex % AppImages.unfurnishedBHK.length];
  } else if (name.contains('furnished')) {
    return AppImages.furnishedBHK[bhkIndex % AppImages.furnishedBHK.length];
  }

  if (name.contains('bungalow'))   return AppImages.bungalow;
  if (name.contains('office'))     return AppImages.office;
  if (name.contains('society'))    return AppImages.society;
  if (name.contains('restaurant')) return AppImages.restaurant;
  if (name.contains('shop'))       return AppImages.shop;
  if (name.contains('school'))     return AppImages.school;
  if (name.contains('car'))        return AppImages.carWash;
  if (name.contains('kitchen'))    return AppImages.kitchen[0];
  if (name.contains('bathroom') || name.contains('bath')) return AppImages.bathroom[0];
  if (name.contains('bedroom') || name.contains('bed'))   return AppImages.bedroom[0];
  if (name.contains('hall'))       return AppImages.hall[0];
  if (name.contains('floor'))      return AppImages.floor[0];
  if (name.contains('window'))     return AppImages.window[0];

  return AppImages.flat;
}

class _CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  final double? branchPrice;
  final bool isUnavailableInBranch;
  final bool hasBranchSelected;
  final VoidCallback? onSelectCity;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    this.branchPrice,
    this.isUnavailableInBranch = false,
    this.hasBranchSelected = false,
    this.onSelectCity,
  });

  @override
  Widget build(BuildContext context) {
    final int quantity    = item['quantity'] ?? 1;
    final double price    = branchPrice ?? (item['price'] ?? 0.0).toDouble();
    final String serviceName = item['service_name'] ?? item['name'] ?? 'Service';

    final String imageUrl = _getImageForService(serviceName);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnavailableInBranch ? Border.all(color: AppColors.secondary.withOpacity(0.4)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppNetworkImage(
                url: imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (isUnavailableInBranch)
                    const Text(
                      'Not available in selected city',
                      style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 12),
                    )
                  else
                    _BlurredAmount(
                      text: '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      blurred: !hasBranchSelected,
                      alignment: MainAxisAlignment.start,
                      onTap: onSelectCity,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: $quantity',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 22),
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final bool hasBranchSelected;
  final bool hasUnavailableItems;
  final VoidCallback onCheckout;
  final VoidCallback? onSelectCity;

  const _CartSummary({
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.hasBranchSelected,
    required this.onCheckout,
    this.hasUnavailableItems = false,
    this.onSelectCity,
  });

  @override
  Widget build(BuildContext context) {
    final bool shouldBlur = !hasBranchSelected || hasUnavailableItems;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (discountAmount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: AppColors.textMuted)),
                _BlurredAmount(
                  text: '₹${totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.black),
                  blurred: shouldBlur,
                  onTap: onSelectCity,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount', style: TextStyle(color: AppColors.green)),
                _BlurredAmount(
                  text: '-₹${discountAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.green),
                  blurred: shouldBlur,
                  onTap: onSelectCity,
                ),
              ],
            ),
            const Divider(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              _BlurredAmount(
                text: '₹${finalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
                blurred: shouldBlur,
                onTap: onSelectCity,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final canCheckout = !shouldBlur;
              String? blockedReason;
              if (!hasBranchSelected) {
                blockedReason = 'Select a city above to enable checkout';
              } else if (hasUnavailableItems) {
                blockedReason = 'Remove items unavailable in this city to continue';
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canCheckout ? onCheckout : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.textMuted.withOpacity(0.3),
                        disabledForegroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (blockedReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      blockedReason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}