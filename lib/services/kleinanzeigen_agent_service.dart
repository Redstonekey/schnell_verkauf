import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ads_agent_key_manager.dart';

class KleinanzeigenAgentAd {
  final String adId;
  final String title;
  final String description;
  final double price;
  KleinanzeigenAgentAd({
    required this.adId,
    required this.title,
    required this.description,
    required this.price,
  });
}

class KleinanzeigenAgentService {
  // API key will be loaded lazily from shared preferences.
  static String? apiKey;
  static bool _loadingKey = false;

  static const String _baseUrl = 'https://api.kleinanzeigen-agent.de/ads/v1/kleinanzeigen/search';
  static const String _defaultCategories = '49,110'; // Electronics > Handy & Telefon as example
  static bool _authFailed = false; // prevents spamming after first 401

  /// Fetch first ad for given search keyword. Returns null if fails.
  static Future<KleinanzeigenAgentAd?> fetchFirstAd(String keyword) async {
    if (keyword.trim().isEmpty) return null;
    if (_authFailed) {
      print('[KleinanzeigenAgentService] Skipping fetch (auth previously failed).');
      return null;
    }
    try {
      if (apiKey == null && !_loadingKey) {
        _loadingKey = true;
        try { apiKey = await AdsAgentKeyManager.getKey(); } finally { _loadingKey = false; }
      }
      final attempts = <Map<String,String>>[
        { 'query': keyword.trim(), 'limit': '1', 'category': _defaultCategories },
        { 'query': keyword.trim().toLowerCase(), 'limit': '1', 'category': _defaultCategories },
        { 'query': keyword.trim(), 'limit': '1' }, // without category filter
        { 'query': keyword.trim().toLowerCase(), 'limit': '1' },
      ];

      for (final params in attempts) {
        final url = Uri.parse(_baseUrl).replace(queryParameters: params);
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (apiKey != null && apiKey!.isNotEmpty) 'ads_key': apiKey!,
        };
        try {
          // Debug print
          // ignore: avoid_print
          print('[KleinanzeigenAgentService] GET ' + url.toString());
          if (apiKey != null) {
            final safe = apiKey!.length > 10 ? apiKey!.substring(0,6) + '...' + apiKey!.substring(apiKey!.length - 4) : apiKey!;
            print('[KleinanzeigenAgentService] Using ads_key (masked): ' + safe + ' length=' + apiKey!.length.toString());
          } else {
            print('[KleinanzeigenAgentService] No ads_key set');
          }
          final resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 12));
          // ignore: avoid_print
          print('[KleinanzeigenAgentService] Status: ${resp.statusCode} len=${resp.body.length}');
          if (resp.statusCode != 200) {
            // ignore: avoid_print
            print('[KleinanzeigenAgentService] Non-200 response body: ${resp.body}');
            if (resp.statusCode == 401) {
              print('[KleinanzeigenAgentService] API key rejected (401). Aborting further attempts.');
              _authFailed = true;
              return null; // stop trying more queries
            }
            if (resp.statusCode == 429) {
              print('[KleinanzeigenAgentService] Rate limit hit (429). Aborting further attempts.');
              return null;
            }
            continue;
          }
          final json = jsonDecode(resp.body);
          final data = json['data'];
          if (data == null || data['ads'] is! List || data['ads'].isEmpty) {
            // ignore: avoid_print
            print('[KleinanzeigenAgentService] Empty ads array for params: ' + params.toString());
            continue; // try next attempt
          }
          final ad = data['ads'][0];
          return KleinanzeigenAgentAd(
            adId: ad['adid']?.toString() ?? '',
            title: ad['title']?.toString() ?? '',
            description: ad['description']?.toString() ?? '',
            price: _parsePrice(ad['price']),
          );
        } catch (e) {
          // ignore: avoid_print
          print('[KleinanzeigenAgentService] Attempt failed: $e params=$params');
          continue;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[KleinanzeigenAgentService] fetchFirstAd outer error: $e');
      return null;
    }
  }

  static double _parsePrice(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  /// Try multiple keywords plus simplified variants; optionally derive from title.
  static Future<KleinanzeigenAgentAd?> fetchAdForKeywords(List<String> keywords, {String? fallbackTitle}) async {
    final set = <String>{};
    for (final k in keywords) {
      if (k.trim().isEmpty) continue;
      set.add(k.trim());
      set.add(k.trim().toLowerCase());
      // Take first two words variant
      final parts = k.split(RegExp(r"\s+"));
      if (parts.length > 2) {
        set.add(parts.take(2).join(' '));
      }
    }
    if (fallbackTitle != null && fallbackTitle.trim().isNotEmpty) {
      final titleParts = fallbackTitle.split(RegExp(r"\s+"));
      if (titleParts.isNotEmpty) {
        // brand + model guess (first 2-3 words)
        set.add(titleParts.take(2).join(' '));
        if (titleParts.length >= 3) set.add(titleParts.take(3).join(' '));
      }
    }
    for (final candidate in set) {
      final ad = await fetchFirstAd(candidate);
      if (ad != null && ad.price > 0) return ad;
  if (_authFailed) break; // stop loop if auth failed
    }
    return null;
  }
}
