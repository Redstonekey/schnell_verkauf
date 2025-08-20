import 'package:flutter/material.dart';
import '../services/kleinanzeigen_service.dart';
import '../services/api_key_manager.dart';
import 'camera_screen.dart';
import 'api_key_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasApiKey = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await ApiKeyManager.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
      _isLoading = false;
    });
  }

  void _navigateToCamera() {
    if (!_hasApiKey) {
      _showApiKeyRequiredDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  void _showApiKeyRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API-Schlüssel erforderlich'),
        content: const Text(
          'Um die KI-Funktionen zu nutzen, müssen Sie zuerst einen Gemini API-Schlüssel konfigurieren.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Einstellungen'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiKeySettingsScreen(),
      ),
    );
    _checkApiKey(); // Refresh API key status
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schnell Verkauf'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            // API Key status warning
            if (!_hasApiKey)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kein API-Schlüssel konfiguriert',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bitte konfigurieren Sie einen Gemini API-Schlüssel in den Einstellungen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _navigateToSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Jetzt konfigurieren'),
                    ),
                  ],
                ),
              ),
            
            // Logo/Icon area
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _hasApiKey ? Colors.orange : Colors.grey,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            const Text(
              'Schnell Verkauf',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            
            // Subtitle
            const Text(
              'Verkaufe deine Produkte schnell und einfach',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.camera_alt, 
                        color: _hasApiKey ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '1. Fotos von deinem Produkt machen',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy, 
                        color: _hasApiKey ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '2. Gemini KI erstellt automatisch Titel, Beschreibung und Preis',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.edit, 
                        color: _hasApiKey ? Colors.orange : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '3. Bearbeiten und direkt bei Kleinanzeigen einstellen',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // Main action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasApiKey ? Colors.orange : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_hasApiKey ? 'Jetzt starten' : 'API-Schlüssel erforderlich'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Login button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  KleinanzeigenService.showLoginWebView(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Bei Kleinanzeigen anmelden',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
