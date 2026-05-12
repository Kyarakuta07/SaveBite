import 'package:equatable/equatable.dart';

import '../../core/utils/safe_parse.dart';

/// User entity matching `GET /auth/me` response.
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.walletBalance = '0',
    this.pointBalance = 0,
    this.totalSaved = '0',
    this.totalRescued = 0,
    this.totalOrders = 0,
    this.tier = 'Mahasiswa Hemat',
    this.tierIcon,
    this.fcmToken,
    this.defaultAddress,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String walletBalance;
  final int pointBalance;
  final String totalSaved;
  final int totalRescued;
  final int totalOrders;
  final String tier;
  final String? tierIcon;
  final String? fcmToken;
  final Map<String, dynamic>? defaultAddress;

  factory User.fromJson(Map<String, dynamic> json) {
    // tier can be String (new format) or Map (legacy/detail)
    String tierName = 'Mahasiswa Hemat';
    String? tierIcon;

    final rawTier = json['tier'];
    if (rawTier is String) {
      tierName = rawTier;
    } else if (rawTier is Map) {
      tierName = rawTier['name'] as String? ?? 'Mahasiswa Hemat';
      tierIcon = rawTier['icon'] as String?;
    }

    // Extract icon from tier_detail if available
    final rawDetail = json['tier_detail'];
    if (rawDetail is Map && tierIcon == null) {
      tierIcon = rawDetail['icon'] as String?;
    }

    return User(
      id: toInt(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      walletBalance: (json['wallet_balance'] ?? '0').toString(),
      pointBalance: toInt(json['point_balance']),
      totalSaved: (json['total_saved'] ?? '0').toString(),
      totalRescued: toInt(json['total_rescued']),
      totalOrders: toInt(json['total_orders']),
      tier: tierName,
      tierIcon: tierIcon,
      fcmToken: json['fcm_token'] as String?,
      defaultAddress: json['default_address'] as Map<String, dynamic>?,
    );
  }

  User copyWith({
    String? name,
    String? phone,
    String? avatar,
    String? walletBalance,
    int? pointBalance,
    String? totalSaved,
    int? totalRescued,
    int? totalOrders,
    String? tier,
    String? tierIcon,
    String? fcmToken,
    Map<String, dynamic>? defaultAddress,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        avatar: avatar ?? this.avatar,
        walletBalance: walletBalance ?? this.walletBalance,
        pointBalance: pointBalance ?? this.pointBalance,
        totalSaved: totalSaved ?? this.totalSaved,
        totalRescued: totalRescued ?? this.totalRescued,
        totalOrders: totalOrders ?? this.totalOrders,
        tier: tier ?? this.tier,
        tierIcon: tierIcon ?? this.tierIcon,
        fcmToken: fcmToken ?? this.fcmToken,
        defaultAddress: defaultAddress ?? this.defaultAddress,
      );

  @override
  List<Object?> get props => [id, name, email];
}
