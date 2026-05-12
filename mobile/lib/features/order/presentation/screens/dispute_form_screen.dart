import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/dispute_repository.dart';

/// Dispute filing form — requires photo + video proof (multipart upload).
///
/// Navigation: `context.push('/dispute/:orderId')`.
class DisputeFormScreen extends ConsumerStatefulWidget {
  const DisputeFormScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<DisputeFormScreen> createState() => _DisputeFormScreenState();
}

class _DisputeFormScreenState extends ConsumerState<DisputeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _picker = ImagePicker();

  XFile? _photo;
  XFile? _video;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file != null) setState(() => _video = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      _showError('Foto bukti wajib dilampirkan');
      return;
    }
    if (_video == null) {
      _showError('Video bukti wajib dilampirkan');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(disputeRepositoryProvider)
        .createDispute(
          orderId: widget.orderId,
          reason: _reasonCtrl.text.trim(),
          photoPath: _photo!.path,
          videoPath: _video!.path,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komplain berhasil dikirim. Tim kami akan merespons dalam 1x24 jam.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      case Failure(:final message):
        _showError(message);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        centerTitle: false,
        title: const Text('Ajukan Komplain'),
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
              // ── Info banner ──
              const _InfoBanner(),
              const SizedBox(height: AppSpacing.lg),

              // ── Order ID chip ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusDef),
                  border: Border.all(
                      color: AppColors.tertiary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 18, color: AppColors.tertiary),
                    const SizedBox(width: 8),
                    Text('Order #${widget.orderId}',
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.tertiary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Reason ──
              _SectionLabel(
                icon: Icons.edit_note_outlined,
                text: 'Alasan Komplain',
                required: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReasonChips(
                onSelect: (v) => setState(() => _reasonCtrl.text = v),
                selectedReason: _reasonCtrl.text,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _reasonCtrl,
                maxLines: 4,
                maxLength: 500,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Alasan komplain wajib diisi';
                  }
                  if (v.trim().length < 20) {
                    return 'Alasan minimal 20 karakter';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText:
                      'Jelaskan masalah yang Anda alami secara detail...',
                  hintStyle: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.outlineVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  contentPadding:
                      const EdgeInsets.all(AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                    borderSide: const BorderSide(
                        color: AppColors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                    borderSide: const BorderSide(
                        color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDef),
                    borderSide:
                        const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Photo upload ──
              _SectionLabel(
                icon: Icons.photo_camera_outlined,
                text: 'Foto Bukti',
                required: true,
              ),
              const SizedBox(height: 4),
              Text('Format JPG/PNG, maks. 10 MB',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              _MediaPickerCard(
                icon: Icons.add_photo_alternate_outlined,
                label: 'Pilih Foto',
                file: _photo,
                isImage: true,
                onPick: _pickPhoto,
                onClear: () => setState(() => _photo = null),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Video upload ──
              _SectionLabel(
                icon: Icons.videocam_outlined,
                text: 'Video Bukti',
                required: true,
              ),
              const SizedBox(height: 4),
              Text('Maks. 60 detik, format MP4/MOV',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              _MediaPickerCard(
                icon: Icons.video_library_outlined,
                label: 'Pilih Video',
                file: _video,
                isImage: false,
                onPick: _pickVideo,
                onClear: () => setState(() => _video = null),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
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
                              strokeWidth: 2.5,
                              color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gavel_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text('Kirim Komplain',
                                style: AppTextStyles.labelLg),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info Banner ─────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: 20, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batas Pengajuan Komplain',
                    style: AppTextStyles.labelLg
                        .copyWith(color: AppColors.secondary)),
                const SizedBox(height: 4),
                Text(
                  'Komplain hanya dapat diajukan dalam 60 menit setelah pesanan diterima. '
                  'Sertakan foto & video sebagai bukti.',
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reason Quick-pick Chips ─────────────────────────────────

class _ReasonChips extends StatelessWidget {
  const _ReasonChips({
    required this.onSelect,
    required this.selectedReason,
  });

  final void Function(String) onSelect;
  final String selectedReason;

  static const _reasons = [
    'Makanan basi / rusak',
    'Kuantitas tidak sesuai',
    'Item berbeda dari deskripsi',
    'Tidak pernah menerima pesanan',
    'Alergi / kontaminasi',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: _reasons.map((r) {
        final selected = selectedReason == r;
        return ChoiceChip(
          label: Text(r),
          selected: selected,
          onSelected: (_) => onSelect(r),
          selectedColor: AppColors.error.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            fontSize: 12,
            color: selected ? AppColors.error : AppColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            side: BorderSide(
              color: selected
                  ? AppColors.error.withValues(alpha: 0.4)
                  : AppColors.outlineVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Media Picker Card ─────────────────────────────────

class _MediaPickerCard extends StatelessWidget {
  const _MediaPickerCard({
    required this.icon,
    required this.label,
    required this.file,
    required this.isImage,
    required this.onPick,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final XFile? file;
  final bool isImage;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          height: isImage ? 160 : 90,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.outlineVariant,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.outlineVariant),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Tap untuk memilih',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    // File selected — show preview
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
            child: isImage
                ? Image.file(
                    File(file!.path),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 90,
                    color: AppColors.surfaceContainerLow,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam,
                            size: 32, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            file!.name,
                            style: AppTextStyles.bodyMd,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Clear button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
          // Success badge
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('Dipilih',
                      style: AppTextStyles.labelSm
                          .copyWith(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ─────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.text,
    this.required = false,
  });

  final IconData icon;
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.labelLg),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}
