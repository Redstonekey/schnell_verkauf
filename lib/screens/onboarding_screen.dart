import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';
import '../services/api_key_manager.dart';
import 'api_key_settings_screen.dart';
import '../services/kleinanzeigen_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _index = 0;
  bool _checkingKey = true;
  bool _hasKey = false;
  bool _loggedIn = false; // Kleinanzeigen Login Status

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadKey();
  }

  Future<void> _loadKey() async {
    _hasKey = await ApiKeyManager.hasApiKey();
    setState(() { _checkingKey = false; });
  }

  void _next() async {
    if (_index == 0) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      return;
    }
    // API Key page (index 1): enforce key set
    if (_index == 1 && !_hasKey) {
      _openApiKeyDialog();
      return;
    }
    if (_index == 1 && _hasKey) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      return;
    }
    // Login page (index 2): enforce login before finishing
    if (_index == 2 && !_loggedIn) {
      _openLoginFlow();
      return;
    }
    // Finish after all gating conditions satisfied
    if (_index == 2 && _loggedIn && _hasKey) {
      await OnboardingService.setCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _openApiKeyDialog() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiKeySettingsScreen()));
    _loadKey();
  }

  Future<void> _openLoginFlow() async {
    await KleinanzeigenService.showLoginWebView(context);
    if (!mounted) return;
    setState(() { _loggedIn = true; });
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        children: [
          if (_index > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              child: const Text('Zurück'),
            )
          else
            const SizedBox(width: 80),
          const Spacer(),
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              _index == 0
                  ? 'Weiter'
                  : _index == 1 && !_hasKey
                      ? 'API Key setzen'
                      : _index == 1 && _hasKey
                          ? 'Weiter'
                          : _index == 2 && !_loggedIn
                              ? 'Bei Kleinanzeigen einloggen'
                              : 'Starten',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingKey) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _index == 0
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Enforce gating
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _IntroPage(),
                    _ApiKeyPage(hasKey: _hasKey, onOpenSettings: _openApiKeyDialog),
                    _LoginInfoPage(loggedIn: _loggedIn, onLogin: _openLoginFlow),
                  ],
                ),
              ),
              _Dots(index: _index, total: 3),
              _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, size: 110, color: Colors.white),
            const SizedBox(height: 32),
            Text('Willkommen bei\nSchnell Verkauf',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erstelle in Sekunden professionelle Kleinanzeigen: Fotos machen, KI analysiert, Texte & Preis automatisch – fertig!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyPage extends StatelessWidget {
  final bool hasKey;
  final VoidCallback onOpenSettings;
  const _ApiKeyPage({required this.hasKey, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.key, size: 100, color: Colors.orange),
          const SizedBox(height: 24),
          Text('Dein kostenloser KI Zugang',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'Für die automatische Analyse und Texterstellung nutzt die App Googles Gemini KI. Du brauchst dafür einen persönlichen (kostenlosen) API Key.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _InfoTile(icon: Icons.lock_open, text: 'Kostenlos & schnell erstellt'),
          _InfoTile(icon: Icons.security, text: 'Nur lokal gespeichert – kein Serverzugriff'),
            _InfoTile(icon: Icons.speed, text: 'Ermöglicht Bildanalyse & Preisvorschlag'),
          const SizedBox(height: 24),
          _StepsBox(steps: const [
            'Gehe zu https://makersuite.google.com/app/apikey',
            'Mit Google Konto anmelden',
            'Neuen API Key erzeugen',
            'Key kopieren & hier einfügen',
          ]),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onOpenSettings,
            icon: Icon(hasKey ? Icons.check_circle : Icons.add),
            label: Text(hasKey ? 'API Key aktualisieren' : 'API Key hinzufügen'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 12),
          if (hasKey)
            const Text('API Key gespeichert ✅', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

class _LoginInfoPage extends StatelessWidget {
  final bool loggedIn;
  final VoidCallback onLogin;
  const _LoginInfoPage({required this.loggedIn, required this.onLogin});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
            const Icon(Icons.account_circle, size: 100, color: Colors.orange),
            const SizedBox(height: 24),
            Text('Login bei Kleinanzeigen', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Melde dich jetzt einmalig bei Kleinanzeigen.de an. Deine Session bleibt per Cookie erhalten. Läuft sie ab, wirst du automatisch wieder zum Login geleitet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: Icon(loggedIn ? Icons.check_circle : Icons.login),
              label: Text(loggedIn ? 'Eingeloggt' : 'Jetzt einloggen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: loggedIn ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (loggedIn)
              const Text('Login gespeichert ✅', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 32),
            const Text(
              'Nach erfolgreichem Login kannst du direkt Anzeigen erstellen – Titel, Beschreibung, Preis und Bilder werden vorbereitet.',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String text; const _InfoTile({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      dense: true,
      title: Text(text),
    );
  }
}

class _StepsBox extends StatelessWidget {
  final List<String> steps; const _StepsBox({required this.steps});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('So holst du dir den Key:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(e.value)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int index; final int total; const _Dots({required this.index, required this.total});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: active ? Colors.orange : Colors.orange.withOpacity(.3),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }
}

class _GradientContainer extends StatelessWidget {
  final Widget child; const _GradientContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
