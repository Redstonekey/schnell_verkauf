import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/product_data.dart';
import 'api_key_manager.dart';
class AIService {
  // Simple in-memory cache + guards to avoid accidental duplicate/rapid requests
  static final Map<String, ProductData> _cache = {};
  static DateTime? _lastRequestTime;
  static bool _inFlight = false;

  static Future<ProductData> analyzeImages(List<String> imagePaths, {String? additionalInfo}) async {
    final cacheKey = '${imagePaths.join('|')}::${additionalInfo ?? ''}';

    // Return cached response if available
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Prevent concurrent requests from the client
    if (_inFlight) {
      throw Exception('Analyse bereits in Arbeit. Bitte warten.');
    }

    // Basic minimum interval protection to avoid rapid repeated calls
    final minInterval = const Duration(seconds: 3);
    if (_lastRequestTime != null) {
      final diff = DateTime.now().difference(_lastRequestTime!);
      if (diff < minInterval) {
        throw Exception('Bitte kurz warten bevor Sie die KI erneut anfragen (Rate-Limit-Schutz)');
      }
    }

    _inFlight = true;
    _lastRequestTime = DateTime.now();

    try {
      // Get API key
      final apiKey = await ApiKeyManager.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Kein API-Schlüssel gesetzt. Bitte in den Einstellungen konfigurieren.');
      }

      // Initialize Gemini model
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp', // Using Gemini 2.0 Flash (latest available)
        apiKey: apiKey,
      );

      // Convert images to Uint8List for Gemini
      List<DataPart> imageParts = [];
      for (String path in imagePaths) {
        final bytes = await File(path).readAsBytes();
        imageParts.add(DataPart('image/jpeg', bytes));
      }

      // Prepare the prompt in German
      String prompt = '''
Analysiere die Bilder eines Produkts und erstelle eine Kleinanzeige auf Deutsch. 
Schaue dir die Bilder genau an und identifiziere das Produkt.''';

      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        prompt += '\n\nZusätzliche Informationen vom Nutzer: $additionalInfo';
      }

      prompt += '''

Erstelle:
- Einen präzisen, aussagekräftigen Titel (max 65 Zeichen)
- Eine detaillierte Beschreibung mit Zustand, Besonderheiten und wichtigen Details
- Einen realistischen Marktpreis in Euro basierend auf dem erkennbaren Zustand

Antworte NUR im folgenden JSON Format (kein anderer Text):
{
  "title": "Produkttitel hier",
  "description": "Detaillierte Beschreibung des Produkts hier",
  "price": 25.50
}
''';

      // Create content with text and images
      final content = [
        Content.multi([
          TextPart(prompt),
          ...imageParts,
        ])
      ];

      // Generate response with retry/backoff for transient 429s. Do NOT retry on explicit quota-exceeded.
      dynamic response;
      const int maxAttempts = 3;
      int attempt = 0;
      while (true) {
        attempt++;
        try {
          response = await model.generateContent(content);
          break;
        } catch (e) {
          final msg = e.toString().toLowerCase();
          // If the service explicitly says quota exceeded, bail out immediately
          if (msg.contains('quota exceeded') || msg.contains('generate content api requests per minute')) {
            // Surface as quota error so outer catch logs it specifically
            throw Exception('Quota exceeded: $e');
          }

          // For transient rate limits (429 / too many requests), retry with exponential backoff
          if ((msg.contains('429') || msg.contains('too many requests') || msg.contains('rate limit')) && attempt < maxAttempts) {
            final backoff = Duration(seconds: 1 << (attempt - 1));
            await Future.delayed(backoff);
            continue;
          }

          // Otherwise rethrow to be handled by outer catch
          rethrow;
        }
      }

      if (response == null || response.text == null || response.text!.isEmpty) {
        throw Exception('Keine Antwort von Gemini erhalten');
      }

      // Parse the JSON response
      final responseText = response.text!.trim();
      
      // Extract JSON from response (in case there's extra text)
      final jsonStart = responseText.indexOf('{');
      final jsonEnd = responseText.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception('Ungültiges JSON-Format in der Antwort');
      }
      
      final jsonString = responseText.substring(jsonStart, jsonEnd);
      final productJson = jsonDecode(jsonString);

      final result = ProductData(
        title: productJson['title']?.toString() ?? 'Unbekanntes Produkt',
        description: productJson['description']?.toString() ?? 'Keine Beschreibung verfügbar',
        price: _parsePrice(productJson['price']),
        imagePaths: imagePaths,
      );

      // Cache a successful result
      try {
        _cache[cacheKey] = result;
      } catch (_) {}

      return result;
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('quota') || msg.contains('Generate Content') || msg.contains('429') || msg.toLowerCase().contains('too many requests')) {
        print('AI Service Rate/Quota Error: $e');
      } else {
        print('AI Service Error: $e');
      }
      // Fallback for demo/testing purposes
      return _createDemoResponse(imagePaths);
    } finally {
      _inFlight = false;
    }
  }
  
  static double _parsePrice(dynamic price) {
    if (price is num) {
      return price.toDouble();
    }
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }

  // Demo response for testing without actual AI service
  static ProductData _createDemoResponse(List<String> imagePaths) {
    return ProductData(
      title: 'Something went wrong...',
      description: 'Try to troubleshoot by checking your API key or network connection. '
          'If you still see this message, please reach out to error@joancode.33mail.com',
      price: 0.0,
      imagePaths: [],
    );
  }
}
