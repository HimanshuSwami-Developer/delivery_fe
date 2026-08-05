import 'package:fastswipe/core/basket_api/json_utils.dart';

/// Mirrors `zones.serializers.ZoneSerializer`.
class ApiZone {
  const ApiZone({
    required this.id,
    required this.name,
    required this.address,
    required this.pincodes,
    required this.avgEtaMinutes,
    required this.isOpen,
    required this.ridersCount,
    required this.ordersToday,
    this.fillRatePct,
  });

  final int id;
  final String name;
  final String address;
  final List<String> pincodes;
  final int avgEtaMinutes;
  final bool isOpen;
  final int ridersCount;
  final int ordersToday;
  final double? fillRatePct;

  factory ApiZone.fromJson(Map<String, dynamic> json) => ApiZone(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String? ?? '',
        pincodes: (json['pincodes'] as List? ?? []).map((e) => e.toString()).toList(),
        avgEtaMinutes: json['avg_eta_minutes'] as int? ?? 12,
        isOpen: json['is_open'] as bool,
        ridersCount: json['riders_count'] as int? ?? 0,
        ordersToday: json['orders_today'] as int? ?? 0,
        fillRatePct: asDoubleOrNull(json['fill_rate_pct']),
      );
}
