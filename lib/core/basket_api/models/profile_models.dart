/// Mirrors `accounts.serializers.AddressItemSerializer` — one entry in
/// `Profile.addresses` (a JSON list server-side, not its own table).
class ApiAddress {
  const ApiAddress({
    required this.id,
    required this.addressType,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String addressType;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final bool isDefault;

  /// Drop-pin captured when this address was saved (see `AddressEditView`'s
  /// map) — null for addresses saved before this existed.
  final double? latitude;
  final double? longitude;

  factory ApiAddress.fromJson(Map<String, dynamic> json) => ApiAddress(
        id: json['id'] as String? ?? '',
        addressType: json['address_type'] as String? ?? 'home',
        addressLine1: json['address_line1'] as String? ?? '',
        addressLine2: json['address_line2'] as String?,
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? 'India',
        pincode: json['pincode'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'address_type': addressType,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'is_default': isDefault,
        'latitude': latitude,
        'longitude': longitude,
      };

  String get oneLine =>
      [addressLine1, addressLine2 ?? '', city].where((s) => s.isNotEmpty).join(', ');
}

/// Mirrors `accounts.serializers.ProfileSerializer`.
class ApiProfile {
  const ApiProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.referralCode,
    required this.loyaltyPoints,
    required this.mobileNumber,
    required this.role,
    required this.addresses,
  });

  final int id;
  final String name;
  final String email;
  final String referralCode;
  final int loyaltyPoints;
  final String mobileNumber;
  final String role;
  final List<ApiAddress> addresses;

  bool get isAdmin => role == 'admin';

  factory ApiProfile.fromJson(Map<String, dynamic> json) => ApiProfile(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        referralCode: json['referral_code'] as String? ?? '',
        loyaltyPoints: json['loyalty_points'] as int? ?? 0,
        mobileNumber: json['mobile_number'] as String? ?? '',
        role: json['role'] as String? ?? 'customer',
        addresses: (json['addresses'] as List? ?? [])
            .map((e) => ApiAddress.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `accounts.serializers.ReferralSerializer` — one entry in
/// `MyReferralsView`'s response.
class ApiReferral {
  const ApiReferral({
    required this.name,
    required this.joinedAt,
    required this.rewardCode,
    required this.rewardAmount,
    required this.rewardRedeemed,
  });

  final String name;
  final DateTime joinedAt;
  final String? rewardCode;
  final int rewardAmount;
  final bool rewardRedeemed;

  factory ApiReferral.fromJson(Map<String, dynamic> json) => ApiReferral(
        name: json['name'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String),
        rewardCode: json['reward_code'] as String?,
        rewardAmount: json['reward_amount'] as int? ?? 0,
        rewardRedeemed: json['reward_redeemed'] as bool? ?? false,
      );
}

/// The full `GET /auth/profile/referrals/` response.
class ReferralSummary {
  const ReferralSummary({
    required this.referralCode,
    required this.totalReferrals,
    required this.totalRewardsEarned,
    required this.referrals,
  });

  final String referralCode;
  final int totalReferrals;
  final int totalRewardsEarned;
  final List<ApiReferral> referrals;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) => ReferralSummary(
        referralCode: json['referral_code'] as String? ?? '',
        totalReferrals: json['total_referrals'] as int? ?? 0,
        totalRewardsEarned: json['total_rewards_earned'] as int? ?? 0,
        referrals: (json['referrals'] as List? ?? [])
            .map((e) => ApiReferral.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `accounts.serializers.LoyaltyTransactionSerializer`.
class ApiLoyaltyTransaction {
  const ApiLoyaltyTransaction({
    required this.id,
    required this.points,
    required this.reason,
    required this.note,
    required this.createdAt,
  });

  final int id;

  /// Positive = earned, negative = redeemed.
  final int points;

  /// 'order_reward' | 'redeemed'
  final String reason;
  final String note;
  final DateTime createdAt;

  factory ApiLoyaltyTransaction.fromJson(Map<String, dynamic> json) => ApiLoyaltyTransaction(
        id: json['id'] as int,
        points: json['points'] as int,
        reason: json['reason'] as String,
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// The full `GET /auth/profile/loyalty/` response.
class LoyaltySummary {
  const LoyaltySummary({
    required this.points,
    required this.minRedeemPoints,
    required this.pointsToRupee,
    required this.transactions,
  });

  final int points;
  final int minRedeemPoints;
  final int pointsToRupee;
  final List<ApiLoyaltyTransaction> transactions;

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) => LoyaltySummary(
        points: json['points'] as int? ?? 0,
        minRedeemPoints: json['min_redeem_points'] as int? ?? 50,
        pointsToRupee: json['points_to_rupee'] as int? ?? 1,
        transactions: (json['transactions'] as List? ?? [])
            .map((e) => ApiLoyaltyTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        access: json['access'] as String,
        refresh: json['refresh'] as String,
      );
}

/// Mirrors the `VerifyOTPView`/`MasterOTPLoginView` response shape.
class LoginResult {
  const LoginResult({required this.tokens, required this.isNewUser, required this.mobileNumber});

  final AuthTokens tokens;
  final bool isNewUser;
  final String mobileNumber;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
        isNewUser: json['is_new_user'] as bool? ?? false,
        mobileNumber: json['mobile_number'] as String? ?? '',
      );
}
