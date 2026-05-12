import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/wallet_transaction.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../providers/wallet_provider.dart';

/// Wallet screen — balance card + transaction history.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).loadWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dompet'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(walletProvider.notifier).loadWallet(),
        child: CustomScrollView(
          slivers: [
            // ── Balance Card ──────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.marginMobile),
                child: _BalanceCard(
                  state: state,
                  onTopUp: () => _showTopUpSheet(context),
                ),
              ),
            ),

            // ── Section Header ──────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile),
                child: Text('Riwayat Transaksi',
                    style: AppTextStyles.headlineSm),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            // ── Transaction List ──────
            if (state.isLoading && state.transactions.isEmpty)
              ShimmerPlaceholder.sliverList(count: 5, itemHeight: 72)
            else if (state.transactions.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Belum ada transaksi',
                  iconSize: 64,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < state.transactions.length) {
                        return _TransactionTile(
                            txn: state.transactions[index]);
                      }
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      );
                    },
                    childCount: state.transactions.length +
                        (state.hasMore ? 1 : 0),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => const _TopUpSheet(),
    );
  }
}

// ─── Balance Card (gradient green) ───────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.state, required this.onTopUp});
  final WalletState state;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF27AE60)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo',
              style: AppTextStyles.labelLg.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            Formatters.rupiah(state.balance),
            style: AppTextStyles.headlineLg.copyWith(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Total Top-up',
                  value: Formatters.rupiah(state.totalTopup),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatChip(
                  label: 'Total Belanja',
                  value: Formatters.rupiah(state.totalSpent),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTopUp,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Top Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelSm.copyWith(color: Colors.white60)),
          Text(value,
              style: AppTextStyles.labelMd.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

// ─── Transaction Tile ────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.txn});
  final WalletTransaction txn;

  IconData _iconForType(String type) {
    switch (type) {
      case 'topup':
        return Icons.add_circle_outline;
      case 'payment':
        return Icons.shopping_bag_outlined;
      case 'refund':
        return Icons.replay;
      case 'commission':
        return Icons.percent;
      case 'withdrawal':
        return Icons.arrow_downward;
      case 'income':
        return Icons.arrow_upward;
      default:
        return Icons.swap_horiz;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'topup':
        return 'Top Up';
      case 'payment':
        return 'Pembayaran';
      case 'refund':
        return 'Refund';
      case 'commission':
        return 'Komisi';
      case 'withdrawal':
        return 'Penarikan';
      case 'income':
        return 'Pendapatan';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.isCredit;
    final color = isCredit ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
              ),
              child: Icon(_iconForType(txn.type), color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),

            // Label + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_labelForType(txn.type),
                      style: AppTextStyles.labelLg),
                  if (txn.description != null)
                    Text(txn.description!,
                        style: AppTextStyles.labelMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${Formatters.rupiah(txn.amount)}',
                  style: AppTextStyles.labelLg.copyWith(color: color),
                ),
                if (txn.createdAt != null)
                  Text(
                    Formatters.relativeTime(txn.createdAt!),
                    style: AppTextStyles.labelSm,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top-Up Bottom Sheet ─────────────────────

class _TopUpSheet extends ConsumerStatefulWidget {
  const _TopUpSheet();

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  int? _selectedPreset;
  final _customCtrl = TextEditingController();
  String _paymentMethod = 'qris';
  bool _isLoading = false;

  static const _presets = [25000, 50000, 100000, 200000];

  static const _paymentMethods = [
    ('qris', Icons.qr_code_2, 'QRIS'),
    ('e_wallet', Icons.phone_android, 'E-Wallet'),
    ('bank_transfer', Icons.account_balance, 'Transfer Bank'),
  ];

  int get _amount {
    if (_selectedPreset != null) return _selectedPreset!;
    return int.tryParse(_customCtrl.text.replaceAll('.', '')) ?? 0;
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal top-up Rp 10.000')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(walletRepositoryProvider).topUp(
          amount: amount,
          paymentMethod: _paymentMethod,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case Success(:final data):
        Navigator.pop(context);
        final paymentUrl = data['payment_url'] as String? ??
            data['payment']?['payment_url'] as String?;
        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          final uri = Uri.parse(paymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Top-up berhasil! 🎉')),
          );
        }
        // Refresh wallet
        ref.read(walletProvider.notifier).loadWallet();

      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Text('Top Up Saldo', style: AppTextStyles.headlineSm),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih nominal atau masukkan jumlah sendiri',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Preset amounts ──
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _presets.map((amount) {
              final isSelected = _selectedPreset == amount;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPreset = isSelected ? null : amount;
                    if (!isSelected) _customCtrl.clear();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    Formatters.rupiah(amount),
                    style: AppTextStyles.labelLg.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Custom amount ──
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) =>
                setState(() => _selectedPreset = null),
            decoration: InputDecoration(
              labelText: 'Nominal lainnya',
              prefixText: 'Rp ',
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusDef),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Payment method ──
          Text('Metode Pembayaran', style: AppTextStyles.labelLg),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _paymentMethods.map((m) {
              final isSelected = _paymentMethod == m.$1;
              return GestureDetector(
                onTap: () =>
                    setState(() => _paymentMethod = m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.$2,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        m.$3,
                        style: AppTextStyles.labelMd.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Submit ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading || _amount < 10000 ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _amount >= 10000
                          ? 'Top Up ${Formatters.rupiah(_amount)}'
                          : 'Masukkan Nominal',
                      style:
                          AppTextStyles.button.copyWith(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
