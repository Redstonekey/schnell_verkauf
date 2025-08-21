import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Manages ad visibility based on a remote GitHub Gist + local family code.
///
/// Gist JSON format example (ads_control.json):
/// {
///   "ads_enabled": true,
///   "codes": {
///     "ABC123": 1,
///     "XYZ789": 3
///   }
/// }
/// - ads_enabled: if false -> hide ads for everyone globally.
/// - codes: map of code -> months of ad-free (integer months)
///
/// Local flow:
/// 1. User enters a family code (stored locally).
/// 2. First validation stores activation timestamp + months.
/// 3. Ad-free until activation + months*30 days (simplified month length).
class AdsService {
  static const _prefsCodeKey = 'family_ad_code';
  static const _prefsCodeActivatedKey = 'family_ad_code_activated';
  static const _prefsCodeMonthsKey = 'family_ad_code_months';

  /// Set this to your raw gist URL (raw.githubusercontent.../gist-id/ads_control.json)
  static String gistRawUrl = 'https://gist.githubusercontent.com/Redstonekey/322388e07b25d512fafec2d8b65f7e41/raw/5e943f9ff17c054452494ea4131e8a161c2c3c95/ads_control.json';

  static final ValueNotifier<bool> showAds = ValueNotifier<bool>(true);
  static final ValueNotifier<String?> activeCode = ValueNotifier<String?>(null);
  static final ValueNotifier<Duration?> remaining = ValueNotifier<Duration?>(null);

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _evaluate();
  }

  /// Returns the stored code (may be expired or invalid remotely).
  static Future<String?> getStoredCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsCodeKey);
  }

  static Future<void> setFamilyCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.trim().isEmpty) {
      await prefs.remove(_prefsCodeKey);
      await prefs.remove(_prefsCodeActivatedKey);
      await prefs.remove(_prefsCodeMonthsKey);
    } else {
      await prefs.setString(_prefsCodeKey, code.trim().toUpperCase());
      // Reset so new months definition can apply
      await prefs.remove(_prefsCodeActivatedKey);
      await prefs.remove(_prefsCodeMonthsKey);
    }
    await _evaluate(forceNetwork: true);
  }

  static Future<void> refresh() => _evaluate(forceNetwork: true);

  static Future<void> _evaluate({bool forceNetwork = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString(_prefsCodeKey);
    final activatedMillis = prefs.getInt(_prefsCodeActivatedKey);
    final storedMonths = prefs.getInt(_prefsCodeMonthsKey);

    Map<String, dynamic> remote = {};
    try {
      final resp = await http.get(Uri.parse(gistRawUrl)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        remote = jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Network failure -> keep previous decision
    }

    final bool adsEnabledRemote = remote['ads_enabled'] != false; // default true
    final Map<String, dynamic> codes = (remote['codes'] is Map<String, dynamic>) ? remote['codes'] : {};

    if (!adsEnabledRemote) {
      showAds.value = false;
      activeCode.value = storedCode;
      remaining.value = null;
      return;
    }

    if (storedCode == null) {
      showAds.value = true; // ads on
      activeCode.value = null;
      remaining.value = null;
      return;
    }

    final codeUpper = storedCode.toUpperCase();
    int? months = codes[codeUpper] is int ? codes[codeUpper] as int : null;
    if (months == null) {
      // Code removed remotely
      showAds.value = true;
      activeCode.value = null;
      remaining.value = null;
      return;
    }

    int? activation = activatedMillis;
    if (activation == null || storedMonths != months) {
      activation = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_prefsCodeActivatedKey, activation);
      await prefs.setInt(_prefsCodeMonthsKey, months);
    }

    final activationDate = DateTime.fromMillisecondsSinceEpoch(activation);
    final expiry = activationDate.add(Duration(days: months * 30));
    final now = DateTime.now();
    if (now.isAfter(expiry)) {
      showAds.value = true; // expired
      activeCode.value = null;
      remaining.value = null;
    } else {
      showAds.value = false;
      activeCode.value = codeUpper;
      remaining.value = expiry.difference(now);
    }
  }
}
