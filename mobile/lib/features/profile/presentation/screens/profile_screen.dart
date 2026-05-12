import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/stitch_components.dart';
import '../../../auth/providers/auth_provider.dart';

/// Profile tab, matched to the Stitch PRD `savebite_profil_saya` screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: StitchTopBar(
                onNotifications: () => context.push('/notifications'),
              ),
            ),
            SliverToBoxAdapter(
              child: _ProfileContent(
                name: user?.name ?? 'Guest',
                email: user?.email ?? '',
                avatar: user?.avatar,
                tier: user?.tier ?? 'Mahasiswa Hemat',
                totalSaved: user?.totalSaved ?? '0',
                totalRescued: user?.totalRescued ?? 0,
                onSettings: () => context.push('/profile/edit'),
                onLogout: () => _confirmLogout(context, ref),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.name,
    required this.email,
    required this.avatar,
    required this.tier,
    required this.totalSaved,
    required this.totalRescued,
    required this.onSettings,
    required this.onLogout,
  });

  final String name;
  final String email;
  final String? avatar;
  final String tier;
  final String totalSaved;
  final int totalRescued;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.md,
            AppSpacing.marginMobile,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              _ProfileHeroCard(
                name: name,
                email: email,
                avatar: avatar,
                tier: tier,
                onSettings: onSettings,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ImpactGrid(totalSaved: totalSaved, totalRescued: totalRescued),
              const SizedBox(height: AppSpacing.lg),
              _ProfileMenuCard(
                items: [
                  _ProfileMenuData(
                    icon: Icons.receipt_long_outlined,
                    label: 'Pesanan Saya',
                    onTap: () => context.push('/orders'),
                  ),
                  _ProfileMenuData(
                    icon: Icons.location_on_outlined,
                    label: 'Alamat Tersimpan',
                    onTap: () => context.push('/addresses'),
                  ),
                  _ProfileMenuData(
                    icon: Icons.help_center_outlined,
                    label: 'Pusat Bantuan',
                    onTap: () {},
                  ),
                  _ProfileMenuData(
                    icon: Icons.gavel_outlined,
                    label: 'Syarat & Ketentuan',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  textStyle: AppTextStyles.labelLg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.avatar,
    required this.tier,
    required this.onSettings,
  });

  final String name;
  final String email;
  final String? avatar;
  final String tier;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return StitchSurfaceCard(
      borderColor: AppColors.outlineVariant.withValues(alpha: 0.20),
      shadow: StitchShadows.ambient,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined, size: 20),
              color: AppColors.onSurfaceVariant,
              style: IconButton.styleFrom(
                fixedSize: const Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: AppColors.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: avatar == null || avatar!.isEmpty
                    ? Center(
                        child: Text(
                          initial,
                          style: AppTextStyles.headlineLg.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      )
                    : AppNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.person,
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(name, style: AppTextStyles.headlineSm),
              if (email.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  email,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _TierBadge(tier: tier),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});
  final String tier;

  static const _tierLabels = {
    'mahasiswa_hemat': 'Mahasiswa Hemat',
    'pemburu_diskon': 'Pemburu Diskon',
    'eco_warrior': 'Eco Warrior',
    'savebite_legend': 'SaveBite Legend',
  };

  static const _tierIcons = {
    'mahasiswa_hemat': Icons.school,
    'pemburu_diskon': Icons.local_offer,
    'eco_warrior': Icons.eco,
    'savebite_legend': Icons.star,
  };

  @override
  Widget build(BuildContext context) {
    final label = _tierLabels[tier] ?? tier;
    final icon = _tierIcons[tier] ?? Icons.workspace_premium;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: AppColors.secondaryContainer.withValues(alpha: 0.50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _ImpactGrid extends StatelessWidget {
  const _ImpactGrid({required this.totalSaved, required this.totalRescued});

  final String totalSaved;
  final int totalRescued;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _SavingsImpactCard(totalSaved: totalSaved)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _RescuedImpactCard(totalRescued: totalRescued)),
        ],
      ),
    );
  }
}

class _SavingsImpactCard extends StatelessWidget {
  const _SavingsImpactCard({required this.totalSaved});
  final String totalSaved;

  @override
  Widget build(BuildContext context) {
    final saved = double.tryParse(totalSaved) ?? 0;
    final progress = (saved / 1000000).clamp(0.0, 1.0);

    return StitchSurfaceCard(
      borderColor: AppColors.outlineVariant.withValues(alpha: 0.20),
      shadow: StitchShadows.ambient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _MiniIcon(icon: Icons.savings_outlined),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Total Hemat',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            Formatters.rupiah(totalSaved),
            style: AppTextStyles.headlineSm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Target: Rp 1Jt',
              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _RescuedImpactCard extends StatelessWidget {
  const _RescuedImpactCard({required this.totalRescued});
  final int totalRescued;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: StitchShadows.ambient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -34,
            child: Icon(
              Icons.eco,
              size: 104,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _MiniIcon(
                    icon: Icons.restaurant,
                    color: Colors.white24,
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Diselamatkan',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalRescued',
                    style: AppTextStyles.headlineLg.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      'Porsi',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '+3 bulan ini',
                  style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({
    required this.icon,
    this.color = AppColors.surfaceContainer,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 14, color: iconColor),
    );
  }
}

class _ProfileMenuData {
  const _ProfileMenuData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.items});
  final List<_ProfileMenuData> items;

  @override
  Widget build(BuildContext context) {
    return StitchSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.outlineVariant.withValues(alpha: 0.20),
      shadow: StitchShadows.ambient,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ProfileMenuItem(data: items[i]),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                indent: 64,
                color: AppColors.surfaceContainerHigh,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.data});
  final _ProfileMenuData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainer,
              ),
              child: Icon(data.icon, size: 21, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                data.label,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
