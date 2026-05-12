import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/utils/image_url_helper.dart';

/// Reusable network image widget with centralized URL resolution,
/// loading shimmer, error fallback, and consistent aspect ratio handling.
///
/// WHY this exists:
/// - Every screen was independently handling null checks, error widgets,
///   and placeholder logic — duplicated across 8+ locations.
/// - Image URLs from the backend need host rewriting (see [ImageUrlHelper]).
/// - This widget ensures consistent UX: shimmer → image or fallback icon.
///
/// Usage:
/// ```dart
/// AppNetworkImage(
///   imageUrl: item.image,        // raw value from API — can be null/relative
///   width: 100,
///   height: 100,
///   fallbackIcon: Icons.restaurant,
/// )
/// ```
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.restaurant,
    this.fallbackIconSize = 32,
    this.borderRadius,
    this.backgroundColor,
  });

  /// Raw image URL from the API. Can be null, empty, relative, or absolute.
  /// Resolved via [ImageUrlHelper.resolve] before loading.
  final String? imageUrl;

  /// Widget dimensions. If null, expands to parent.
  final double? width;
  final double? height;

  /// How the image should fit within its bounds.
  final BoxFit fit;

  /// Icon to show when image is null or fails to load.
  final IconData fallbackIcon;

  /// Size of the fallback icon.
  final double fallbackIconSize;

  /// Border radius for clipping. If null, no clipping.
  final BorderRadius? borderRadius;

  /// Background color for placeholder and error states.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ImageUrlHelper.resolve(imageUrl);
    final bgColor = backgroundColor ?? AppColors.surfaceContainerHigh;

    // DEBUG: trace image URL resolution
    if (kDebugMode) {
      debugPrint('[AppNetworkImage] raw=$imageUrl → resolved=$resolvedUrl');
    }

    Widget child;

    if (resolvedUrl == null) {
      // No image available — show fallback
      child = _fallbackWidget(bgColor);
    } else {
      child = CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _loadingWidget(bgColor),
        errorWidget: (context, url, error) {
          if (kDebugMode) {
            debugPrint('[AppNetworkImage] ERROR loading $url: $error');
          }
          return _fallbackWidget(bgColor);
        },
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }

    if (width != null || height != null) {
      child = SizedBox(width: width, height: height, child: child);
    }

    return child;
  }

  Widget _loadingWidget(Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Center(
        child: SizedBox(
          width: fallbackIconSize * 0.6,
          height: fallbackIconSize * 0.6,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _fallbackWidget(Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: fallbackIconSize,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
