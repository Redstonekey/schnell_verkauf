import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/product_data.dart';
import 'api_key_manager.dart';

class AIService {
  static Future<ProductData> analyzeImages(List<String> imagePaths) async {
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
      const prompt = '''
Analysiere die Bilder eines Produkts und erstelle eine Kleinanzeige auf Deutsch. 
Schaue dir die Bilder genau an und identifiziere das Produkt.

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

      // Generate response
      final response = await model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
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

      return ProductData(
        title: productJson['title']?.toString() ?? 'Unbekanntes Produkt',
        description: productJson['description']?.toString() ?? 'Keine Beschreibung verfügbar',
        price: _parsePrice(productJson['price']),
        imagePaths: imagePaths,
      );
    } catch (e) {
      print('AI Service Error: $e');
      // Fallback for demo/testing purposes
      return _createDemoResponse(imagePaths);
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
      title: 'Smartphone in gutem Zustand',
      description: 'Gut erhaltenes Smartphone mit wenigen Gebrauchsspuren. '
          'Funktioniert einwandfrei, Akku hält noch gut. '
          'Verkauf wegen Neukauf. Privatverkauf, keine Garantie.',
      price: 150.0,
      imagePaths: imagePaths,
    );
  }
}
