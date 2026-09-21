# Pixi – My Year in Pixels

Flutter-App (iOS + Android, DE/EN). Ein Jahr, ein Bild, ein Pixel pro Tag.

## Einmalig einrichten

Der Ordner enthält `lib/`, `assets/`, `pubspec.yaml` – die Plattform-Ordner
(`ios/`, `android/`) erzeugt Flutter selbst:

```bash
cd pixi_app
flutter create . --org de.deinname --project-name pixi --platforms ios,android
flutter pub get
dart run flutter_launcher_icons        # App-Icon aus assets/icon/icon.png
flutter run
```

Benötigt Flutter **3.27 oder neuer** (`flutter --version`).

### Android – zwei Zeilen für Benachrichtigungen

`flutter_local_notifications` braucht Core-Library-Desugaring. In
`android/app/build.gradle.kts` (bzw. `build.gradle`):

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true          // Groovy: coreLibraryDesugaringEnabled true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

In `android/app/src/main/AndroidManifest.xml` innerhalb von `<manifest>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

und innerhalb von `<application>`:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    </intent-filter>
</receiver>
```

### iOS

Nichts Zusätzliches nötig. Minimum iOS 13 (`ios/Podfile`: `platform :ios, '13.0'`).

## Struktur

```
lib/
  main.dart                 Start, lädt Daten, ProviderScope
  app.dart                  MaterialApp, Onboarding ↔ Home, Notification-Tap → Check-in
  core/
    theme.dart              Farben, Schriften (Fraunces + Manrope), ThemeData
    strings.dart            DE/EN-Texte, `@key`-Auflösung für Vorlagen
    dates.dart              Datums-Helfer, Jahres-Matrix
    stats.dart              Statistik + Korrelation
    demo_data.dart          Beispiel-Daten für Onboarding/Vorlagen
  models/
    pix_map.dart            PixMap, MapLevel, Settings, AppData (+JSON)
    templates.dart          Vorlagen in Kategorien, Grundfarben
  data/
    repository.dart         JSON-Datei im App-Dokumente-Ordner
    providers.dart          Riverpod-State (appProvider) + Free-Limit (4 Maps)
  services/
    notification_service.dart  tägliche Erinnerung
    share_service.dart         Widget → PNG → Share-Sheet
    premium_service.dart       Kauf-Stub (→ RevenueCat)
  widgets/
    pixi_cat.dart           5-Frame-Katze („Boil“-Animation), GlowingCat
    pixel_grid.dart         Jahresraster 12×31 mit Glow, Legende
    circle_year.dart        Rund-Ansicht wie das Poster (Voronoi-Mosaik, Katze mittig)
    ui.dart                 Buttons, Karten, LevelPicker, MapCard, Fortschrittsbalken
  features/
    onboarding/             9 Schritte im Amy-Stil, Map-Carousel
    home/                   Jahresansicht (Swipe zwischen Maps), Tag-Sheet
    checkin/                Morgen-Flow
    maps/                   Übersicht, Vorlagen, Editor
    stats/                  Statistik & Zusammenhänge (Premium)
    circle/                 Poster-Ansicht + Teilen
    premium/                Paywall (Jahr / Lifetime)
    settings/               Erinnerung, Name, Export, Feedback
    feedback/               Prompt nach erster Map & erstem Check-in
```

## Katze austauschen / weitere Katzen

Frames liegen in `assets/cats/cat_1.png … cat_5.png` (transparent, 800 px).
Für eine eigene Katze pro Map: Dateien `assets/cats/<catId>_1..5.png` ablegen,
`PixMap.catId` setzen – `PixiCat.asset()` in `widgets/pixi_cat.dart` löst den Pfad auf.

## Offen / bewusst noch Stub

- **Käufe**: `services/premium_service.dart` gibt im Stub immer „gekauft“ zurück.
  Für den Live-Betrieb `purchases_flutter` einbinden (Anleitung im Kommentar der Datei).
  Im Debug-Build gibt es in den Einstellungen einen Premium-Schalter zum Testen.
- **Feedback-Mail** geht an `kFeedbackEmail` in `features/feedback/feedback_sheet.dart`.
- **flutter_local_notifications** ist auf 17.x gepinnt. Beim Update auf 19+ die Zeile
  `uiLocalNotificationDateInterpretation` in `notification_service.dart` entfernen.
- Kaltstart über eine angetippte Benachrichtigung öffnet die App (nicht direkt den Check-in).
