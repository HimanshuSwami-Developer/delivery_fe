import 'package:fastswipe/core/basket_api/json_utils.dart';

/// Mirrors `delivery.serializers.DeliveryPartnerSerializer`.
class ApiDeliveryPartner {
  const ApiDeliveryPartner({
    required this.id,
    required this.mobileNumber,
    required this.partnerCode,
    required this.name,
    required this.vehicle,
    required this.zoneId,
    required this.zoneName,
    required this.rating,
    required this.status,
    required this.tripsToday,
    this.onTimePct,
    required this.earningsThisMonthPaise,
  });

  final int id;
  final String mobileNumber;
  final String partnerCode;
  final String name;
  final String vehicle;
  final int zoneId;
  final String zoneName;
  final double rating;

  /// 'available' | 'on_trip' | 'off_duty'
  final String status;
  final int tripsToday;
  final double? onTimePct;
  final int earningsThisMonthPaise;

  int get earningsThisMonthRupees => earningsThisMonthPaise ~/ 100;

  factory ApiDeliveryPartner.fromJson(Map<String, dynamic> json) => ApiDeliveryPartner(
        id: json['id'] as int,
        mobileNumber: json['mobile_number'] as String? ?? '',
        partnerCode: json['partner_code'] as String,
        name: json['name'] as String,
        vehicle: json['vehicle'] as String,
        zoneId: json['zone'] as int,
        zoneName: json['zone_name'] as String,
        rating: asDouble(json['rating'], fallback: 5),
        status: json['status'] as String,
        tripsToday: json['trips_today'] as int? ?? 0,
        onTimePct: asDoubleOrNull(json['on_time_pct']),
        earningsThisMonthPaise: json['earnings_this_month_paise'] as int? ?? 0,
      );
}
