import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/food_item.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/models/user_address.dart';
import '../../../../shared/widgets/stitch_components.dart';
import '../../../address/providers/address_provider.dart';
import '../../../wallet/providers/wallet_provider.dart';
import '../../data/repositories/order_repository.dart';
import '../../providers/order_provider.dart';

/// Checkout screen — item summary, address, payment method, notes, place order.
///
/// Route: `/checkout` (push, receives `FoodItem` via GoRouter `extra`)
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({required this.item, super.key});
  final FoodItem item;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _quantity = 1;
  String _paymentMethod = 'wallet';
  final _notesCtrl = TextEditingController();
  UserAddress? _selectedAddress;
  bool _isSubmitting = false;

  /// Estimated flat delivery fee shown pre-checkout.
  ///
  /// WHY a named constant: The backend calculates the real fee based on
  /// distance/provider at `POST /orders` time. Until a pre-checkout fee
  /// estimation endpoint is available, this is the best-effort client
  /// estimate. The pricing summary labels it accordingly.
  static const double _estimatedDeliveryFee = 12000;

  int get _maxQty => widget.item.stockRemaining;
  double get _rescuePrice => double.tryParse(widget.item.rescuePrice) ?? 0;
  double get _lineTotal => _rescuePrice * _quantity;
  double get _deliveryFee => widget.item.pickupOnly ? 0 : _estimatedDeliveryFee;
  double get _total => _lineTotal + _deliveryFee;

  @override
  void initState() {
    super.initState();
    // Ensure addresses & wallet are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addrState = ref.read(addressProvider);
      if (addrState.addresses.isEmpty) {
        ref.read(addressProvider.notifier).loadAddresses();
      }
      final walletState = ref.read(walletProvider);
      if (walletState.balance == '0' && !walletState.isLoading) {
        ref.read(walletProvider.notifier).loadWallet();
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ─── Place Order ─────────────────────────────

  Future<void> _placeOrder() async {
    final addr = _selectedAddress ?? ref.read(addressProvider).defaultAddress;

    if (addr == null) {
      _showSnack('Pilih alamat pengiriman terlebih dahulu');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(orderRepositoryProvider)
        .createOrder(
          merchantId: widget.item.merchant!.id,
          items: [
            {'food_item_id': widget.item.id, 'quantity': _quantity},
          ],
          paymentMethod: _paymentMethod,
          deliveryAddress: addr.address,
          deliveryLat: addr.latitude ?? 0,
          deliveryLng: addr.longitude ?? 0,
          notes: _notesCtrl.text.trim().isNotEmpty
              ? _notesCtrl.text.trim()
              : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success(:final data):
        // Refresh order list
        ref.read(orderListProvider.notifier).loadOrders();
        // Refresh wallet balance
        ref.read(walletProvider.notifier).loadWallet();

        final paymentUrl = data['payment']?['payment_url'] as String?;
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          // Non-wallet: open Midtrans payment page
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
          if (mounted) context.go('/orders');
        } else {
          // Wallet payment: go directly to order detail
          final orderId =
              data['order']?['id'] as int? ?? data['id'] as int? ?? 0;
          if (mounted) {
            _showSnack('Pesanan berhasil dibuat! 🎉');
            context.go('/orders');
            if (orderId > 0) {
              context.push('/orders/$orderId');
            }
          }
        }

      case Failure(:final message):
        _showSnack(message);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final addrState = ref.watch(addressProvider);
    final walletState = ref.watch(walletProvider);
    final currentAddr = _selectedAddress ?? addrState.defaultAddress;
    final walletBalance = double.tryParse(walletState.balance) ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineSm.copyWith(
          color: AppColors.onSurface,
        ),
        backgroundColor: AppColors.surface.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.surfaceVariant),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          132,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DeliveryToggle(pickupOnly: widget.item.pickupOnly),
            const SizedBox(height: AppSpacing.md),

            _AddressSection(
              address: currentAddr,
              isLoading: addrState.isLoading,
              onChangePressed: () => _showAddressPicker(),
              onAddPressed: () async {
                await context.push('/addresses/add');
                if (mounted) {
                  ref.read(addressProvider.notifier).loadAddresses();
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _ItemSummaryCard(
              item: widget.item,
              quantity: _quantity,
              lineTotal: _lineTotal,
              maxQty: _maxQty,
              onQtyChanged: (q) => setState(() => _quantity = q),
            ),
            const SizedBox(height: AppSpacing.md),

            if (!widget.item.pickupOnly) ...[
              const _LogisticsSection(),
              const SizedBox(height: AppSpacing.md),
            ],

            _PaymentMethodSection(
              selected: _paymentMethod,
              walletBalance: walletBalance,
              onChanged: (m) => setState(() => _paymentMethod = m),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Notes
            _NotesField(controller: _notesCtrl),
            const SizedBox(height: AppSpacing.lg),

            // 5. Pricing summary
            _PricingSummary(
              lineTotal: _lineTotal,
              deliveryFee: _deliveryFee,
              total: _total,
              isPickupOnly: widget.item.pickupOnly,
            ),
          ],
        ),
      ),
      bottomNavigationBar: StitchBottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    Formatters.rupiah(_total),
                    style: AppTextStyles.headlineSm.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 184,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text('Bayar Sekarang', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Address Picker Bottom Sheet ─────────────

  void _showAddressPicker() {
    final addresses = ref.read(addressProvider).addresses;
    if (addresses.isEmpty) {
      _showSnack('Belum ada alamat. Tambahkan alamat pengiriman.');
      context.push('/addresses/add').then((_) {
        if (mounted) {
          ref.read(addressProvider.notifier).loadAddresses();
        }
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Alamat', style: AppTextStyles.headlineSm),
                const SizedBox(height: AppSpacing.md),
                ...addresses.map(
                  (addr) => ListTile(
                    leading: Icon(
                      addr.isDefault
                          ? Icons.bookmark
                          : Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(addr.label, style: AppTextStyles.labelLg),
                    subtitle: Text(
                      addr.address,
                      style: AppTextStyles.labelMd,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                        _selectedAddress?.id == addr.id ||
                            (_selectedAddress == null && addr.isDefault)
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedAddress = addr);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeliveryToggle extends StatelessWidget {
  const _DeliveryToggle({required this.pickupOnly});
  final bool pickupOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              icon: Icons.local_shipping_outlined,
              label: 'Pesan Antar',
              selected: !pickupOnly,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              icon: Icons.storefront,
              label: 'Ambil Sendiri',
              selected: pickupOnly,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: selected ? StitchShadows.card : const [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item Summary Card ───────────────────────────

class _ItemSummaryCard extends StatelessWidget {
  const _ItemSummaryCard({
    required this.item,
    required this.quantity,
    required this.lineTotal,
    required this.maxQty,
    required this.onQtyChanged,
  });

  final FoodItem item;
  final int quantity;
  final double lineTotal;
  final int maxQty;
  final ValueChanged<int> onQtyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: StitchShadows.card,
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.image != null
                  ? AppNetworkImage(
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.restaurant,
                      backgroundColor: AppColors.surfaceContainerHigh,
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.labelLg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.rupiah(item.rescuePrice),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Qty selector
                Row(
                  children: [
                    _QtyBtn(
                      icon: Icons.remove,
                      onTap: quantity > 1
                          ? () => onQtyChanged(quantity - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: AppTextStyles.labelLg.copyWith(
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    _QtyBtn(
                      icon: Icons.add,
                      onTap: quantity < maxQty
                          ? () => onQtyChanged(quantity + 1)
                          : null,
                    ),
                    const Spacer(),
                    Text(
                      Formatters.rupiah(lineTotal),
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.surfaceContainerHigh,
    child: const Icon(Icons.restaurant, color: AppColors.textSecondary),
  );
}

class _LogisticsSection extends StatelessWidget {
  const _LogisticsSection();

  @override
  Widget build(BuildContext context) {
    return StitchSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pengiriman', style: AppTextStyles.labelLg),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainer,
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GrabExpress Instan', style: AppTextStyles.labelLg),
                      Text(
                        'Estimasi: 15-30 menit',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Address Section ─────────────────────────────

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.address,
    required this.isLoading,
    required this.onChangePressed,
    required this.onAddPressed,
  });

  final UserAddress? address;
  final bool isLoading;
  final VoidCallback onChangePressed;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: StitchShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Alamat Pengiriman', style: AppTextStyles.labelLg),
              const Spacer(),
              if (address != null)
                GestureDetector(
                  onTap: onChangePressed,
                  child: Text(
                    'Ganti',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (address != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address!.label,
                  style: AppTextStyles.labelLg.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${address!.recipientName} • ${address!.phone}',
                  style: AppTextStyles.labelMd,
                ),
                const SizedBox(height: 2),
                Text(
                  address!.address,
                  style: AppTextStyles.bodyMd,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Alamat'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

// ─── Payment Method Section ──────────────────────

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({
    required this.selected,
    required this.walletBalance,
    required this.onChanged,
  });

  final String selected;
  final double walletBalance;
  final ValueChanged<String> onChanged;

  static const _methods = [
    ('wallet', Icons.account_balance_wallet, 'Wallet'),
    ('qris', Icons.qr_code_2, 'QRIS'),
    ('e_wallet', Icons.phone_android, 'E-Wallet'),
    ('bank_transfer', Icons.account_balance, 'Transfer Bank'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: StitchShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Metode Pembayaran', style: AppTextStyles.labelLg),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _methods.map((m) {
              final isSelected = selected == m.$1;
              final isWallet = m.$1 == 'wallet';
              return GestureDetector(
                onTap: () => onChanged(m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerHighest,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m.$2,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.$3,
                            style: AppTextStyles.labelMd.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isWallet)
                            Text(
                              Formatters.rupiah(walletBalance),
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Notes Field ─────────────────────────────────

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: StitchShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Catatan (opsional)', style: AppTextStyles.labelLg),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Contoh: tolong pisahkan saus',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: AppTextStyles.bodyMd,
          ),
        ],
      ),
    );
  }
}

// ─── Pricing Summary ─────────────────────────────

class _PricingSummary extends StatelessWidget {
  const _PricingSummary({
    required this.lineTotal,
    required this.deliveryFee,
    required this.total,
    required this.isPickupOnly,
  });

  final double lineTotal;
  final double deliveryFee;
  final double total;
  final bool isPickupOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: StitchShadows.card,
      ),
      child: Column(
        children: [
          _row('Subtotal', Formatters.rupiah(lineTotal)),
          const SizedBox(height: 8),
          _row(
            isPickupOnly ? 'Ongkir (pickup)' : 'Ongkir (estimasi)',
            isPickupOnly ? 'Gratis' : Formatters.rupiah(deliveryFee),
            valueColor: isPickupOnly ? AppColors.success : null,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Bayar',
                style: AppTextStyles.labelLg.copyWith(fontSize: 15),
              ),
              Text(
                Formatters.rupiah(total),
                style: AppTextStyles.price.copyWith(fontSize: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMd),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
