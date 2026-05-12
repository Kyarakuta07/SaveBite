import 'package:equatable/equatable.dart';

import '../../core/utils/safe_parse.dart';

/// User saved address entity matching backend API response.
class UserAddress extends Equatable {
  const UserAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.address,
    this.detail,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
  });

  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String address;
  final String? detail;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime? createdAt;

  factory UserAddress.fromJson(Map<String, dynamic> json) => UserAddress(
        id: toInt(json['id']),
        label: json['label'] as String? ?? '',
        recipientName: json['recipient_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        detail: json['detail'] as String?,
        latitude: toDoubleOrNull(json['latitude']),
        longitude: toDoubleOrNull(json['longitude']),
        isDefault: toBool(json['is_default']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'address': address,
        if (detail != null) 'detail': detail,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'is_default': isDefault,
      };

  @override
  List<Object?> get props => [id, label, isDefault];
}
