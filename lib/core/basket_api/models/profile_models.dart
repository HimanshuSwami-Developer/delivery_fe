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
      };

  String get oneLine =>
      [addressLine1, addressLine2 ?? '', city].where((s) => s.isNotEmpty).join(', ');
}

/// Mirrors `accounts.serializers.ProfileSerializer`.
class ApiProfile {
  const ApiProfile({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.role,
    required this.addresses,
  });

  final int id;
  final String name;
  final String mobileNumber;
  final String role;
  final List<ApiAddress> addresses;

  bool get isAdmin => role == 'admin';

  factory ApiProfile.fromJson(Map<String, dynamic> json) => ApiProfile(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        mobileNumber: json['mobile_number'] as String? ?? '',
        role: json['role'] as String? ?? 'customer',
        addresses: (json['addresses'] as List? ?? [])
            .map((e) => ApiAddress.fromJson(e as Map<String, dynamic>))
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
