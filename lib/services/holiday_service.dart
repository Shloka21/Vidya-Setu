import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_model.dart';

class HolidayService {
  static const String _baseUrl = 'https://date.nager.at/api/v3/publicholidays';
  static const String _cacheKey = 'cached_holidays';
  static const String _cacheDateKey = 'cached_holidays_date';

  /// Fetch holidays for a given year and country (default: India)
  static Future<List<HolidayInfo>> getHolidays({
    int? year,
    String countryCode = 'IN',
  }) async {
    final targetYear = year ?? DateTime.now().year;

    // Try cache first
    final cached = await _getCachedHolidays(targetYear);
    if (cached != null) return cached;

    // Fetch from API
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$targetYear/$countryCode'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final holidays = data.map((item) {
          return HolidayInfo(
            date: DateTime.parse(item['date']),
            name: item['localName'] ?? item['name'] ?? 'Holiday',
            type: _mapType(item['types'] ?? []),
          );
        }).toList();

        // Cache the result
        await _cacheHolidays(holidays, targetYear);
        return holidays;
      }
    } catch (e) {
      // API failed, use fallback
    }

    // Fallback: hardcoded major Indian holidays
    return _getFallbackHolidays(targetYear);
  }

  static String _mapType(List<dynamic> types) {
    if (types.contains('Public')) return 'national';
    if (types.contains('Optional')) return 'festival';
    return 'regional';
  }

  static Future<List<HolidayInfo>?> _getCachedHolidays(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString('${_cacheDateKey}_$year');
      if (cachedDate == null) return null;

      // Check if cache is less than 30 days old
      final cacheTime = DateTime.parse(cachedDate);
      if (DateTime.now().difference(cacheTime).inDays > 30) return null;

      final cachedData = prefs.getString('${_cacheKey}_$year');
      if (cachedData == null) return null;

      final List<dynamic> data = json.decode(cachedData);
      return data.map((item) => HolidayInfo.fromMap(item)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<void> _cacheHolidays(
      List<HolidayInfo> holidays, int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_cacheKey}_$year',
          json.encode(holidays.map((h) => h.toMap()).toList()));
      await prefs.setString(
          '${_cacheDateKey}_$year', DateTime.now().toIso8601String());
    } catch (e) {
      // Cache failure is non-critical
    }
  }

  /// Check if a specific date is a holiday
  static bool isHoliday(DateTime date, List<HolidayInfo> holidays) {
    return holidays.any((h) =>
        h.date.year == date.year &&
        h.date.month == date.month &&
        h.date.day == date.day);
  }

  /// Get the holiday name for a date (if it is a holiday)
  static String? getHolidayName(DateTime date, List<HolidayInfo> holidays) {
    try {
      return holidays
          .firstWhere((h) =>
              h.date.year == date.year &&
              h.date.month == date.month &&
              h.date.day == date.day)
          .name;
    } catch (e) {
      return null;
    }
  }

  /// Fallback holidays for India when API is unavailable
  static List<HolidayInfo> _getFallbackHolidays(int year) {
    return [
      HolidayInfo(
          date: DateTime(year, 1, 26),
          name: 'Republic Day',
          type: 'national'),
      HolidayInfo(
          date: DateTime(year, 3, 14), name: 'Holi', type: 'festival'),
      HolidayInfo(
          date: DateTime(year, 3, 31),
          name: 'Id-ul-Fitr',
          type: 'festival'),
      HolidayInfo(
          date: DateTime(year, 4, 14),
          name: 'Dr. Ambedkar Jayanti',
          type: 'national'),
      HolidayInfo(
          date: DateTime(year, 4, 18),
          name: 'Good Friday',
          type: 'festival'),
      HolidayInfo(
          date: DateTime(year, 5, 1),
          name: 'Maharashtra Day',
          type: 'regional'),
      HolidayInfo(
          date: DateTime(year, 8, 15),
          name: 'Independence Day',
          type: 'national'),
      HolidayInfo(
          date: DateTime(year, 10, 2),
          name: 'Gandhi Jayanti',
          type: 'national'),
      HolidayInfo(
          date: DateTime(year, 10, 20), name: 'Diwali', type: 'festival'),
      HolidayInfo(
          date: DateTime(year, 10, 21),
          name: 'Diwali (Day 2)',
          type: 'festival'),
      HolidayInfo(
          date: DateTime(year, 11, 1),
          name: 'Diwali Padwa',
          type: 'festival'),
      HolidayInfo(
          date: DateTime(year, 12, 25),
          name: 'Christmas',
          type: 'festival'),
    ];
  }
}
