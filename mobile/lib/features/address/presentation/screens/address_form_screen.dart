import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'location_picker_screen.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/user_address.dart';
import '../../providers/address_provider.dart';

/// Form screen for creating or editing a [UserAddress].
///
/// Pass `extra: UserAddress` via GoRouter to pre-populate (edit mode).
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  /// Non-null = edit mode. Null = create mode.
  final UserAddress? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _isDefault = false;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _labelCtrl.text = e.label;
      _recipientCtrl.text = e.recipientName;
      _phoneCtrl.text = e.phone;
      _addressCtrl.text = e.address;
      _detailCtrl.text = e.detail ?? '';
      _isDefault = e.isDefault;
      _latitude = e.latitude;
      _longitude = e.longitude;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    bool success;
    if (_isEdit) {
      success = await ref.read(addressProvider.notifier).updateAddress(
            id: widget.existing!.id,
            label: _labelCtrl.text.trim(),
            recipientName: _recipientCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            detail: _detailCtrl.text.trim().isEmpty
                ? null
                : _detailCtrl.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
            isDefault: _isDefault,
          );
    } else {
      success = await ref.read(addressProvider.notifier).createAddress(
            label: _labelCtrl.text.trim(),
            recipientName: _recipientCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            detail: _detailCtrl.text.trim().isEmpty
                ? null
                : _detailCtrl.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
            isDefault: _isDefault,
          );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEdit ? 'Alamat berhasil diperbarui' : 'Alamat ditambahkan'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(addressProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Terjadi kesalahan, coba lagi'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
        title: Text(_isEdit ? 'Edit Alamat' : 'Tambah Alamat'),
        titleTextStyle: AppTextStyles.headlineSm,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Label ──
              _SectionLabel(
                icon: Icons.label_outline,
                text: 'Label Alamat',
              ),
              const SizedBox(height: AppSpacing.xs),
              _QuickLabelChips(
                selected: _labelCtrl.text,
                onSelect: (opt) => setState(() => _labelCtrl.text = opt),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildField(
                controller: _labelCtrl,
                hint: 'Rumah, Kantor, Kost ...',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Label wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Recipient ──
              _SectionLabel(
                icon: Icons.person_outline,
                text: 'Penerima',
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildField(
                controller: _recipientCtrl,
                hint: 'Nama penerima',
                keyboardType: TextInputType.name,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama penerima wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildField(
                controller: _phoneCtrl,
                hint: 'No. telepon (08xx...)',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Telepon wajib diisi';
                  if (!RegExp(r'^0[0-9]{9,12}$').hasMatch(v)) {
                    return 'Format nomor tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Address ──
              _SectionLabel(
                icon: Icons.location_on_outlined,
                text: 'Alamat Pengiriman',
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Pick on Map button ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openLocationPicker,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDef),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                  ),
                  icon: Icon(
                    _latitude != null
                        ? Icons.edit_location_alt
                        : Icons.add_location_alt,
                    size: 20,
                  ),
                  label: Text(
                    _latitude != null
                        ? 'Ubah Titik Lokasi di Peta'
                        : 'Pilih Lokasi di Peta',
                    style: AppTextStyles.labelLg
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),

              // ── Coordinate badge (only shown once picked) ──
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Lokasi: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          style: AppTextStyles.labelMd
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              _buildField(
                controller: _addressCtrl,
                hint: 'Jl. Merdeka No.10, Kelurahan...',
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildField(
                controller: _detailCtrl,
                hint: 'Detail (gedung, lantai, patokan) — opsional',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Default toggle ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: SwitchListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  activeThumbColor: AppColors.primary,
                  title: Text('Jadikan alamat utama',
                      style: AppTextStyles.bodyMd),
                  subtitle: Text(
                    'Dipakai secara default saat checkout',
                    style: AppTextStyles.labelMd
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  secondary: Icon(
                    Icons.star,
                    color: _isDefault
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDef),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Alamat',
                          style: AppTextStyles.labelLg),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to the full-screen map picker and handle the result.
  Future<void> _openLocationPicker() async {
    final result = await context.push<PickedLocation>(
      '/location-picker',
      extra: _latitude != null
          ? {'lat': _latitude!, 'lng': _longitude!}
          : null,
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        // Auto-fill address field if it was empty.
        if (_addressCtrl.text.trim().isEmpty) {
          _addressCtrl.text = result.address;
        }
      });
    }
  }
}

// ─── Quick Label Chips ─────────────────────────────────

class _QuickLabelChips extends StatelessWidget {
  const _QuickLabelChips({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final void Function(String) onSelect;

  static const _options = ['Rumah', 'Kantor', 'Kost'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: _options.map((opt) {
        final isSelected = selected == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onSelect(opt),
          selectedColor: AppColors.primary.withValues(alpha: 0.12),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.outlineVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Build Field Helper ─────────────────────────────────

extension on _AddressFormScreenState {
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd
            .copyWith(color: AppColors.outlineVariant),
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDef),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.labelLg),
      ],
    );
  }
}
