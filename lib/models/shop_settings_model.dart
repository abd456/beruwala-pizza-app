import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one day's opening hours entry from Firestore.
class DayHours {
  final bool isClosedAllDay;
  final String open;  // "HH:mm"
  final String close; // "HH:mm"

  const DayHours({
    required this.isClosedAllDay,
    required this.open,
    required this.close,
  });

  factory DayHours.fromMap(Map<String, dynamic> map) {
    return DayHours(
      isClosedAllDay: map['isClosedAllDay'] as bool? ?? false,
      open: map['open'] as String? ?? '00:00',
      close: map['close'] as String? ?? '00:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isClosedAllDay': isClosedAllDay,
      'open': open,
      'close': close,
    };
  }
}

class ShopSettingsModel {
  final bool isManuallyClosedNow;
  final int estimatedWaitMinutes;
  final Map<String, DayHours> weeklyHours;

  const ShopSettingsModel({
    required this.isManuallyClosedNow,
    required this.estimatedWaitMinutes,
    required this.weeklyHours,
  });

  /// Ordered list used for display and iteration in the settings screen.
  static const List<String> daysOfWeek = [
    'monday', 'tuesday', 'wednesday', 'thursday',
    'friday', 'saturday', 'sunday',
  ];

  /// Returns a default fully-open schedule (09:00–22:00, no days closed).
  static ShopSettingsModel defaults() {
    const defaultDay = DayHours(
      isClosedAllDay: false,
      open: '09:00',
      close: '22:00',
    );
    return ShopSettingsModel(
      isManuallyClosedNow: false,
      estimatedWaitMinutes: 30,
      weeklyHours: {for (final d in daysOfWeek) d: defaultDay},
    );
  }

  factory ShopSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawHours = data['weeklyHours'] as Map<String, dynamic>? ?? {};

    final hours = <String, DayHours>{};
    for (final day in daysOfWeek) {
      final dayData = rawHours[day] as Map<String, dynamic>?;
      hours[day] = dayData != null
          ? DayHours.fromMap(dayData)
          : const DayHours(isClosedAllDay: false, open: '09:00', close: '22:00');
    }

    return ShopSettingsModel(
      isManuallyClosedNow: data['isManuallyClosedNow'] as bool? ?? false,
      estimatedWaitMinutes: data['estimatedWaitMinutes'] as int? ?? 30,
      weeklyHours: hours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isManuallyClosedNow': isManuallyClosedNow,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'weeklyHours': {
        for (final entry in weeklyHours.entries) entry.key: entry.value.toMap()
      },
    };
  }

  // ─── Computed ───────────────────────────────────────────────────────────────

  /// Pure synchronous check — no async, just DateTime.now().
  bool get isOpenRightNow {
    if (isManuallyClosedNow) return false;

    final now = DateTime.now();
    // Dart's weekday: 1=Monday … 7=Sunday
    final dayName = daysOfWeek[now.weekday - 1];
    final todayHours = weeklyHours[dayName];

    if (todayHours == null || todayHours.isClosedAllDay) return false;

    final open = _parseTime(todayHours.open, now);
    final close = _parseTime(todayHours.close, now);

    return now.isAfter(open) && now.isBefore(close);
  }

  /// Returns a human-readable "next open" string, e.g. "Mon 09:00".
  /// Used in the customer banner. Returns null when unable to determine.
  String? get nextOpenDescription {
    final now = DateTime.now();
    // Search up to 7 days ahead
    for (int offset = 0; offset < 7; offset++) {
      final candidate = now.add(Duration(days: offset));
      final dayName = daysOfWeek[candidate.weekday - 1];
      final hours = weeklyHours[dayName];
      if (hours == null || hours.isClosedAllDay) continue;

      final openTime = _parseTime(hours.open, candidate);
      // If same day, make sure open time hasn't passed yet
      if (offset == 0 && !now.isBefore(openTime)) continue;

      final dayLabel = offset == 0
          ? 'today'
          : offset == 1
              ? 'tomorrow'
              : _shortDayName(dayName);
      return '$dayLabel at ${hours.open}';
    }
    return null;
  }

  static DateTime _parseTime(String hhmm, DateTime base) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  static String _shortDayName(String day) {
    return '${day[0].toUpperCase()}${day.substring(1, 3)}';
  }
}
