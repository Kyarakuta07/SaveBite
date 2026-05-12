import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Data class returned when user confirms a location.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

/// Full-screen map picker for selecting a delivery address.
///
/// Opens centred on the user's current GPS position (or Jakarta default).
/// A fixed pin sits at the map centre — dragging the map moves the pin.
/// On confirm, reverse-geocodes the centre and pops with a [PickedLocation].
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  /// Pre-set latitude (edit mode). Null = use device GPS.
  final double? initialLat;

  /// Pre-set longitude (edit mode). Null = use device GPS.
  final double? initialLng;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;

  /// Default fallback: Central Jakarta.
  static const _jakartaCenter = LatLng(-6.2088, 106.8456);

  late LatLng _currentCenter;
  String _addressText = 'Mencari alamat...';
  bool _isGeocoding = false;
  bool _isLoadingLocation = true;

  /// Debounce timer so we don't geocode every single camera-move frame.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentCenter = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _jakartaCenter;

    // Only fetch GPS if no initial coordinates were supplied.
    if (widget.initialLat == null) {
      _determinePosition();
    } else {
      _isLoadingLocation = false;
      _reverseGeocode(_currentCenter);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────

  Future<void> _determinePosition() async {
    try {
      // Check if location services are enabled.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _reverseGeocode(_currentCenter);
        return;
      }

      // Check & request permissions.
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          setState(() => _isLoadingLocation = false);
          _reverseGeocode(_currentCenter);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = newCenter;
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(newCenter));
      _reverseGeocode(newCenter);
    } catch (_) {
      // Fallback to Jakarta if anything goes wrong.
      setState(() => _isLoadingLocation = false);
      _reverseGeocode(_currentCenter);
    }
  }

  // ── Reverse Geocoding ───────────────────────────────

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isGeocoding = true);
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Build readable address from placemark components.
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.subAdministrativeArea != null &&
              p.subAdministrativeArea!.isNotEmpty)
            p.subAdministrativeArea!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
          if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
        ];
        setState(() {
          _addressText =
              parts.isNotEmpty ? parts.join(', ') : 'Alamat tidak ditemukan';
        });
      } else {
        setState(() => _addressText = 'Alamat tidak ditemukan');
      }
    } catch (_) {
      setState(() => _addressText = 'Gagal mendapatkan alamat');
    } finally {
      setState(() => _isGeocoding = false);
    }
  }

  // ── Map Callbacks ───────────────────────────────────

  void _onCameraMove(CameraPosition pos) {
    _currentCenter = pos.target;
  }

  void _onCameraIdle() {
    // Debounce: wait 500ms after user stops dragging before geocoding.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _reverseGeocode(_currentCenter);
    });
  }

  void _onMyLocationTap() async {
    await _determinePosition();
  }

  void _onConfirm() {
    final result = PickedLocation(
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      address: _addressText,
    );
    context.pop(result);
  }

  // ── Build ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Google Map (full screen) ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 16.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // custom button below
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // ── Centre Pin (always at map centre) ──
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36), // offset for pin tip
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: AppColors.error, // red pin
              ),
            ),
          ),

          // ── Top Bar (back + title) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Pilih Lokasi Pengiriman',
                          style: AppTextStyles.labelLg,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── My Location FAB ──
          Positioned(
            right: AppSpacing.md,
            bottom: 200,
            child: _CircleButton(
              icon: Icons.my_location,
              onTap: _onMyLocationTap,
            ),
          ),

          // ── Bottom Card (address preview + confirm) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.lg,
                AppSpacing.marginMobile,
                AppSpacing.xl,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Pin icon + label ──
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusDef),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Alamat Terpilih',
                                  style: AppTextStyles.labelLg),
                              const SizedBox(height: 2),
                              _isGeocoding || _isLoadingLocation
                                  ? Row(
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Mencari alamat...',
                                          style: AppTextStyles.labelMd
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _addressText,
                                      style: AppTextStyles.bodyMd.copyWith(
                                          color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Confirm Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: (_isGeocoding || _isLoadingLocation)
                            ? null
                            : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusDef),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text('Gunakan Lokasi Ini',
                            style: AppTextStyles.labelLg
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circle Button (reused for back + my-location) ─────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
