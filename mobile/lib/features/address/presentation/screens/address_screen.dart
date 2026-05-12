import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_address.dart';
import '../../providers/address_provider.dart';

/// Full-screen address list with add/edit/delete/set-default actions.
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressProvider.notifier).loadAddresses();
    });
  }

  Future<void> _delete(UserAddress addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: Text('Hapus "${addr.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(addressProvider.notifier).deleteAddress(addr.id);
    }
  }

  Future<void> _setDefault(UserAddress addr) async {
    if (addr.isDefault) return;
    await ref.read(addressProvider.notifier).setDefault(addr.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${addr.label}" dijadikan alamat utama'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
        title: const Text('Alamat Tersimpan'),
        titleTextStyle: AppTextStyles.headlineSm,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/addresses/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Alamat'),
      ),
      body: Builder(
        builder: (innerCtx) {
          if (state.isLoading && state.addresses.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state.error != null && state.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.error!, style: AppTextStyles.bodyMd),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        ref.read(addressProvider.notifier).loadAddresses(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          if (state.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined,
                      size: 64, color: AppColors.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Belum ada alamat tersimpan',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Tap tombol + untuk menambahkan',
                      style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(addressProvider.notifier).loadAddresses(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.md,
                AppSpacing.marginMobile,
                120, // space for FAB
              ),
              itemCount: state.addresses.length,
              separatorBuilder: (context, i) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final addr = state.addresses[i];
                return _AddressCard(
                  address: addr,
                  onEdit: () => context.push('/addresses/edit', extra: addr),
                  onDelete: () => _delete(addr),
                  onSetDefault: () => _setDefault(addr),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Address Card ─────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final UserAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: address.isDefault
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.surfaceVariant,
          width: address.isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    address.label,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('Utama',
                            style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.success)),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Action menu
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                    if (val == 'default') onSetDefault();
                  },
                  itemBuilder: (_) => [
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(children: [
                          Icon(Icons.star_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Jadikan Utama'),
                        ]),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Hapus',
                            style:
                                TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
                  child: const Icon(Icons.more_vert,
                      size: 20, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Recipient info
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(address.recipientName,
                    style: AppTextStyles.bodyMd),
                const SizedBox(width: 12),
                const Icon(Icons.phone_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(address.phone,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address.detail != null
                        ? '${address.address}, ${address.detail}'
                        : address.address,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant),
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
