# Schnell Verkaufen

Eine deutsche AI-App zum schnellen Verkaufen von Produkten über Kleinanzeigen.de.

## Funktionen

  - Produkttitel (max 65 Zeichen)
  - Detaillierte Beschreibung
  - Realistischen Preis in Euro

## Ad Control (Family No-Ad Codes)

You can disable ads globally or per family code using a public GitHub Gist.

1. Create (or edit) a Gist file named `ads_control.json`.
2. Put JSON like this:

```json
{
  "ads_enabled": true,
  "codes": {
    "ABC123": 1,
    "FAMILY2025": 3,
    "VIP999": 12
  }
}
```

Fields:
- `ads_enabled`: set `false` to turn off ads for everyone instantly.
- `codes`: map of `CODE_STRING` -> months of ad‑free (integer). Each month = 30 days (simplified).

3. Copy the Raw URL of that Gist and set `AdsService.gistRawUrl` in `lib/services/ads_service.dart`.
4. Distribute codes to family. Long‑press the Home screen title to enter or clear a code. Remaining ad‑free time shows on the Home screen while active.

Revoking / extending:
- Delete a code or change its months value; next refresh (app launch or re‑entry) updates entitlement.
- Set `ads_enabled` to `false` for a global ad shutdown.

Security note: This is a lightweight convenience system; Gist is public. Don’t reuse sensitive codes.
## Setup

### 1. Gemini API-Schlüssel erhalten

1. Besuche [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Melde dich mit deinem Google-Konto an
3. Klicke auf "Create API Key"
4. Kopiere den generierten Schlüssel

### 2. API-Schlüssel in der App konfigurieren

1. Öffne die Schnell Verkaufen App
2. Tippe auf das Einstellungs-Symbol (⚙️) oben rechts
3. Füge deinen API-Schlüssel ein
4. Tippe auf "Speichern"

## Nutzung

### Schritt 1: Fotos aufnehmen
- Tippe auf "Jetzt starten"
- Mache mehrere Fotos von verschiedenen Winkeln
- Oder wähle Bilder aus der Galerie

### Schritt 2: KI-Analyse
- Überprüfe die ausgewählten Fotos
- Tippe auf "Mit KI analysieren"
- Warte auf die Gemini-Analyse

### Schritt 3: Bearbeiten
- Überprüfe und bearbeite:
  - Titel
  - Beschreibung
  - Preis
- Alle Felder können angepasst werden

### Schritt 4: Bei Kleinanzeigen veröffentlichen
1. **Anmelden**: Tippe auf "Bei Kleinanzeigen anmelden" 
2. **Automatisches Ausfüllen**: Tippe auf "Anzeige aufgeben"
   - Titel wird automatisch eingefügt
   - Preis wird automatisch eingefügt  
   - Beschreibung wird automatisch eingefügt
3. **Bilder hinzufügen**: Wähle die Fotos manuell aus der Galerie aus
4. **Veröffentlichen**: Vervollständige die Anzeige auf Kleinanzeigen.de

## Technische Details

- **KI-Modell**: Google Gemini 2.0 Flash
- **Framework**: Flutter
- **Plattformen**: Android, iOS
- **Sicherheit**: API-Schlüssel wird lokal gespeichert

## Wichtige Hinweise

- ⚠️ **API-Schlüssel erforderlich**: Ohne Gemini API-Schlüssel funktioniert die KI-Analyse nicht
- 📱 **Berechtigungen**: Kamera- und Speicher-Zugriff erforderlich
- 🌐 **Internetverbindung**: Für KI-Analyse und Kleinanzeigen-Integration notwendig
- 💾 **Lokale Speicherung**: Fotos werden automatisch in der Galerie gespeichert
- 🔒 **Datenschutz**: API-Schlüssel wird nur lokal auf dem Gerät gespeichert

## Fehlerbehebung

### "API-Schlüssel nicht konfiguriert"
- Gehe zu Einstellungen (⚙️)
- Füge einen gültigen Gemini API-Schlüssel hinzu

### "Kamera kann nicht initialisiert werden"
- Überprüfe Kamera-Berechtigungen in den Geräte-Einstellungen
- Starte die App neu

### "Fehler bei der KI-Analyse"
- Überprüfe Internetverbindung
- Überprüfe API-Schlüssel Gültigkeit
- Versuche es mit weniger/anderen Bildern

### Kleinanzeigen.de Integration
- Stelle sicher, dass du angemeldet bist
- Bilder müssen manuell aus der Galerie ausgewählt werden
- Andere Felder werden automatisch ausgefüllt

## Development

```bash
# Dependencies installieren
flutter pub get

# App starten
flutter run

# Build für Android
flutter build apk

# Build für iOS  
flutter build ios
```

## Lizenz

Dieses Projekt ist für private Nutzung erstellt.
