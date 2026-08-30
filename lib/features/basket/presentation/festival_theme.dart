import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:flutter/material.dart';

/// Which decorative motif [FestivalOverlay] draws for a given theme.
enum FestivalMotif { diyaLights, colorSplash, snowfall, confetti }

/// A festival re-skin for the home header — swaps in for
/// [BasketColors.headerGradient] and [BasketColors.gold] while active, plus
/// a decorative overlay, a greeting badge, and a one-time popup. Everything
/// else in the app (nav, checkout, product cards) stays on the normal
/// navy/ivory palette — only the home header re-skins, same as Blinkit/
/// Zepto's festival takeovers.
///
/// Built from the [Festivals] catalog below, then merged with an admin's
/// [ApiFestivalSetting] (colours/motif/text/on-off) by [FestivalCalendar] —
/// see [FestivalCalendar.activeOn].
class FestivalTheme {
  const FestivalTheme({
    required this.id,
    required this.greeting,
    required this.gradient,
    required this.accent,
    required this.motif,
    required this.popupTitle,
    required this.popupMessage,
    this.popupEnabled = true,
  });

  final String id;
  final String greeting;
  final Gradient gradient;
  final Color accent;
  final FestivalMotif motif;
  final String popupTitle;
  final String popupMessage;
  final bool popupEnabled;

  FestivalTheme _mergedWith(ApiFestivalSetting? override) {
    if (override == null) return this;

    final accent = _parseHex(override.accentColor) ?? this.accent;
    final start = _parseHex(override.gradientStart);
    final end = _parseHex(override.gradientEnd);
    final gradient = (start != null && end != null) ? _recolor(this.gradient, start, end) : this.gradient;
    final motif = _motifFromKey(override.motif) ?? this.motif;

    return FestivalTheme(
      id: id,
      greeting: override.greetingText.isNotEmpty ? override.greetingText : greeting,
      gradient: gradient,
      accent: accent,
      motif: motif,
      popupTitle: override.popupTitle.isNotEmpty ? override.popupTitle : popupTitle,
      popupMessage: override.popupMessage.isNotEmpty ? override.popupMessage : popupMessage,
      popupEnabled: override.popupEnabled,
    );
  }
}

Color? _parseHex(String hex) {
  final cleaned = hex.replaceFirst('#', '').trim();
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final value = int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
  return value == null ? null : Color(value);
}

FestivalMotif? _motifFromKey(String key) {
  for (final m in FestivalMotif.values) {
    if (m.name == key) return m;
  }
  return null;
}

/// Re-tints [base] with [start]/[end] while preserving its shape (linear vs
/// radial, angle, center) — so an admin-edited colour pair still looks like
/// "this festival's header", not a generic gradient.
Gradient _recolor(Gradient base, Color start, Color end) {
  if (base is LinearGradient) return LinearGradient(begin: base.begin, end: base.end, colors: [start, end]);
  if (base is RadialGradient) return RadialGradient(center: base.center, radius: base.radius, colors: [start, end], stops: base.stops);
  return base;
}

class Festivals {
  Festivals._();

  static const diwali = FestivalTheme(
    id: 'diwali',
    greeting: 'Happy Diwali! Festive picks inside ✨',
    gradient: RadialGradient(center: Alignment(-0.5, -1), radius: 1.4, colors: [Color(0xFF6B2A17), Color(0xFF3B120A)], stops: [0, 0.75]),
    accent: Color(0xFFF3B14A),
    motif: FestivalMotif.diyaLights,
    popupTitle: 'Happy Diwali! 🪔',
    popupMessage: 'Celebrate with festive prices on your favourite picks.',
  );

  static const holi = FestivalTheme(
    id: 'holi',
    greeting: 'Happy Holi! Colours of savings 🎉',
    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B2D8E), Color(0xFF1F6FB2)]),
    accent: Color(0xFFFFC94D),
    motif: FestivalMotif.colorSplash,
    popupTitle: 'Happy Holi! 🎉',
    popupMessage: 'Splash into Holi deals across the store.',
  );

  static const christmas = FestivalTheme(
    id: 'christmas',
    greeting: 'Merry Christmas! Holiday deals are here 🎄',
    gradient: RadialGradient(center: Alignment(-0.5, -1), radius: 1.4, colors: [Color(0xFF1E4B3A), Color(0xFF0B2A20)], stops: [0, 0.75]),
    accent: Color(0xFFE6B450),
    motif: FestivalMotif.snowfall,
    popupTitle: 'Merry Christmas! 🎄',
    popupMessage: 'Unwrap holiday offers on groceries & gifts.',
  );

  static const newYear = FestivalTheme(
    id: 'new_year',
    greeting: 'Happy New Year! Fresh deals to start the year 🎆',
    gradient: RadialGradient(center: Alignment(-0.5, -1), radius: 1.4, colors: [Color(0xFF241B4E), Color(0xFF0A1F3C)], stops: [0, 0.75]),
    accent: Color(0xFFF3B14A),
    motif: FestivalMotif.confetti,
    popupTitle: 'Happy New Year! 🎆',
    popupMessage: 'Start the year with fresh savings.',
  );

  static const independenceDay = FestivalTheme(
    id: 'independence_day',
    greeting: 'Happy Independence Day! Freedom sale is live 🇮🇳',
    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A1F3C), Color(0xFF1F6F4A)]),
    accent: Color(0xFFF3B14A),
    motif: FestivalMotif.confetti,
    popupTitle: 'Happy Independence Day! 🇮🇳',
    popupMessage: 'Celebrate with our Freedom Sale.',
  );

  /// Same theme/row as [independenceDay] — Republic Day just triggers it on
  /// a second date (see [FestivalCalendar._builtInActive]).
  static const republicDay = independenceDay;

  static const rakshaBandhan = FestivalTheme(
    id: 'raksha_bandhan',
    greeting: 'Happy Raksha Bandhan! Rakhi specials inside 🎗️',
    gradient: RadialGradient(center: Alignment(-0.5, -1), radius: 1.4, colors: [Color(0xFF8A1E3B), Color(0xFF43101E)], stops: [0, 0.75]),
    accent: Color(0xFFF3B14A),
    motif: FestivalMotif.diyaLights,
    popupTitle: 'Happy Raksha Bandhan! 🎗️',
    popupMessage: 'Rakhi specials & gifting deals inside.',
  );

  static const all = [diwali, holi, christmas, newYear, independenceDay, rakshaBandhan];
}

class _Window {
  const _Window(this.start, this.end);
  final DateTime start;
  final DateTime end;
  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
}

/// Resolves "today's" active festival, if any, merged with an admin's
/// [ApiFestivalSetting] override (colours/motif/text, and force-on/
/// force-off/auto) — pass the list from [BasketState.apiFestivalSettings].
/// With no settings loaded yet (e.g. first frame before the network call
/// lands), every festival behaves as `auto` with its app-default styling.
///
/// Fixed-date festivals (Christmas, New Year, Republic Day, Independence
/// Day) recur automatically every year from their Gregorian date. Diwali,
/// Holi, and Raksha Bandhan follow the lunisolar calendar and shift every
/// year, so their peak dates are looked up from [_diwaliPeak]/[_holiPeak]/
/// [_rakhiPeak] below — extend those tables each year from an official
/// panchang, or have the admin set that festival's `starts_on`/`ends_on` for
/// the year instead (an explicit admin date range always wins over these).
class FestivalCalendar {
  FestivalCalendar._();

  static final Map<int, DateTime> _diwaliPeak = {
    2025: DateTime(2025, 10, 20),
    2026: DateTime(2026, 11, 8),
    2027: DateTime(2027, 10, 29),
  };

  static final Map<int, DateTime> _holiPeak = {
    2025: DateTime(2025, 3, 14),
    2026: DateTime(2026, 3, 3),
    2027: DateTime(2027, 3, 22),
  };

  static final Map<int, DateTime> _rakhiPeak = {
    2025: DateTime(2025, 8, 9),
    2026: DateTime(2026, 8, 30),
  };

  static FestivalTheme? activeToday({List<ApiFestivalSetting> settings = const []}) =>
      activeOn(DateTime.now(), settings: settings);

  static FestivalTheme? activeOn(DateTime date, {List<ApiFestivalSetting> settings = const []}) {
    final day = DateTime(date.year, date.month, date.day);

    for (final base in Festivals.all) {
      ApiFestivalSetting? override;
      for (final s in settings) {
        if (s.key == base.id) {
          override = s;
          break;
        }
      }

      if (override?.overrideMode == 'force_off') continue;
      if (override?.overrideMode == 'force_on') return base._mergedWith(override);

      final hasExplicitWindow = override?.startsOn != null && override?.endsOn != null;
      final isActive = hasExplicitWindow ? _Window(override!.startsOn!, override.endsOn!).contains(day) : _builtInActive(base.id, day);

      if (isActive) return base._mergedWith(override);
    }

    return null;
  }

  static bool _builtInActive(String id, DateTime day) {
    switch (id) {
      case 'diwali':
        final peak = _diwaliPeak[day.year];
        return peak != null && _Window(peak.subtract(const Duration(days: 2)), peak.add(const Duration(days: 2))).contains(day);
      case 'holi':
        final peak = _holiPeak[day.year];
        return peak != null && _Window(peak.subtract(const Duration(days: 1)), peak.add(const Duration(days: 1))).contains(day);
      case 'raksha_bandhan':
        final peak = _rakhiPeak[day.year];
        return peak != null && _Window(peak.subtract(const Duration(days: 1)), peak.add(const Duration(days: 1))).contains(day);
      case 'christmas':
        return _annual(day.year, 12, 25, before: 5, after: 1).contains(day);
      case 'new_year':
        // Two windows for the same turn: Jan 1-2 of `day.year` (the day
        // after) and Dec 30-31 of `day.year` (the day before) — together
        // span Dec 30 through Jan 2 across the year boundary.
        return _annual(day.year, 1, 1, before: 1, after: 1).contains(day) || _annual(day.year, 12, 31, before: 1, after: 0).contains(day);
      case 'independence_day':
        // Shares this row with Republic Day (Jan 26) — either date lights it up.
        return _annual(day.year, 8, 15, before: 3, after: 0).contains(day) || _annual(day.year, 1, 26, before: 3, after: 0).contains(day);
      default:
        return false;
    }
  }

  static _Window _annual(int year, int month, int day, {required int before, required int after}) {
    final peak = DateTime(year, month, day);
    return _Window(peak.subtract(Duration(days: before)), peak.add(Duration(days: after)));
  }
}
