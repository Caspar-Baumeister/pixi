# Pixi: Bericht

## Website & SEO (13. Oktober 2026)

Die Website in `docs/` wurde komplett neu gebaut: statisches HTML ohne Build-Schritt, Englisch als Hauptsprache plus Deutsch, 14 indexierbare Seiten, dazu Datenschutz, Impressum und 404 (noindex). Veröffentlicht wird sie per GitHub Pages aus `main` im Ordner `/docs` unter https://caspar-baumeister.github.io/pixi/ . Alle App-Store-URLs funktionieren weiter: `/pixi/`, `/pixi/support.html`, `/pixi/privacy.html`.

### Keyword-Map

| Seite | URL | Sprache | Primär-Keyword | Sekundär |
|---|---|---|---|---|
| Startseite | /pixi/ | EN | year in pixels app | mood tracker app, year in pixels mood tracker, pixel diary app, cute mood tracker |
| Ratgeber Vorlage | /pixi/guides/year-in-pixels-template/ | EN | year in pixels template | year in pixels printable, template free, year in pixels pdf, how to make a year in pixels |
| Ratgeber Ideen | /pixi/guides/year-in-pixels-ideas/ | EN | year in pixels ideas | what to track in a year in pixels, tracker ideas, categories, themes, temperature |
| Ratgeber Farben | /pixi/guides/year-in-pixels-color-key/ | EN | year in pixels key | year in pixels colors, color code, key ideas |
| Ratgeber Bullet Journal | /pixi/guides/bullet-journal-mood-tracker/ | EN | bullet journal mood tracker | mood tracker ideas, mood tracker ideas easy, monthly mood tracker |
| Ratgeber Mood Diary | /pixi/guides/mood-diary/ | EN | mood diary | how to track your mood, mood diary template, mood diary app |
| Übersicht Guides | /pixi/guides/ | EN | (Hub) | year in pixels guides |
| Support | /pixi/support.html | EN | (Marke) | pixi app support |
| Startseite | /pixi/de/ | DE | mood tracker app | jahr in pixeln, stimmungstracker app, stimmungstagebuch app, year in pixels app |
| Ratgeber Vorlage | /pixi/de/ratgeber/mood-tracker-vorlage/ | DE | mood tracker vorlage | kostenlos, zum ausdrucken, pdf, jahr in pixeln vorlage |
| Ratgeber Ideen | /pixi/de/ratgeber/mood-tracker-ideen/ | DE | mood tracker ideen | bullet journal mood tracker ideen, was tracken, farben |
| Ratgeber Stimmungstagebuch | /pixi/de/ratgeber/stimmungstagebuch/ | DE | stimmungstagebuch | stimmungstagebuch führen, stimmungstagebuch vorlage |
| Übersicht Ratgeber | /pixi/de/ratgeber/ | DE | (Hub) | mood tracker ratgeber |
| Hilfe | /pixi/de/hilfe/ | DE | (Marke) | pixi hilfe |

hreflang-Paare: Startseiten, Hubs, Support/Hilfe, Vorlage EN/DE, Bullet Journal EN mit Mood Tracker Ideen DE, Mood Diary EN mit Stimmungstagebuch DE. Ideen EN und Farben EN haben kein deutsches Gegenstück.

### Quellen der Recherche

* App Store (Astro): year in pixels US Popularität 13, Difficulty 9, Pixi auf Rang 230. jahr in pixeln DE Rang 1. mood tracker US 53/60 und DE 47/52 (schwer). stimmungstagebuch DE 13/41, Rang 100. gefühlstagebuch DE 7/23.
* Google Suggest EN: "year in pixels" ergänzt zu ideas, template, journal, printable, app, tracker, pdf, mood tracker, excel template. "year in pixels t" zu template free download, template 2026, temperature, themes. "year in pixels c" zu colors, color code, categories, chart. "year in pixels k" zu key, key ideas. Fragen: what is a year in pixels, what to track in a year in pixels, how to make a year in pixels. "mood tracker" zu app, printable, bullet journal, ideas. "bullet journal mood tracker" zu ideas, template, printable, colors und Monatsnamen. "mood diary" zu pdf, app, template, nhs.
* Google Suggest DE: "mood tracker" zu vorlage, app, bullet journal, deutsch, vorlage kostenlos, zum ausdrucken. "mood tracker vorlage" zu kostenlos, zum ausdrucken, pdf, deutsch. "stimmungstagebuch" zu vorlage pdf, app, kostenlos, depression, zum ausdrucken. "stimmungstracker" zu vorlage, app. "mood tracker ideen" zu bullet journal mood tracker ideen. "jahr in pixeln" nur mein jahr in pixeln (kleine Nachfrage, daher kein eigener Ratgeber).
* SERP: year in pixels template, printable und ideas sind voller Spam- und Doorway-Seiten und kleiner Blogs (littlecoffeefox, archerandolive), also gut machbar. bullet journal mood tracker: Blogs (littlecoffeefox, craftsyhacks, archerandolive, gathered.how), mittel. mood tracker app: Medical News Today und App-Store-Seiten, schwer, deshalb nur Sekundär auf der Startseite. mood diary: calm.com, Bipolar UK, NHS-Trusts, mittel bis schwer. mood tracker vorlage: ClickUp und Spam, machbar. stimmungstagebuch führen: BetterHelp und App-Seiten, mittel. stimmungstracker app: Apotheken Umschau, Utopia, App-Seiten, mittel.
* Keine Konkurrenzmarken (Daylio, Pixa, Finch) in Titeln oder H1.

### Seiten und Inhalte

* Startseite EN/DE: Hero mit echtem Screenshot und Katze, Beispiel-Jahr als Pixelband (einmalige Einblend-Animation), Ablauf in drei Schritten, alle 16 App-Vorlagen mit ihren echten Farbskalen, Zusammenhänge (Premium), Poster-Ansicht, Datenschutz, Free und Premium (ohne Preisangaben), Ratgeber-Liste, FAQ, "Made by Caspar".
* Kostenlose Vorlage als PDF: `docs/downloads/year-in-pixels-template-a4.pdf`, `...-letter.pdf`, `mood-tracker-vorlage-a4.pdf` (deutsch). Dazu eine Druckfunktion direkt auf der Seite, die nur das Raster druckt.
* Gesundheitsthemen (Mood Diary, Stimmungstagebuch): sachlich, Hinweis "keine Behandlung, keine Diagnose", Krisennummern (988, Samaritans 116 123, TelefonSeelsorge 0800 111 0 111, Info-Telefon Depression 0800 33 44 533), Quellen: Bipolar UK, NHS Every Mind Matters, Deutsche Depressionshilfe, Apotheken Umschau, Lieberman 2007 (PubMed).
* Support (EN) und Hilfe (DE) mit 10 FAQ, jeweils FAQPage-JSON-LD.
* Datenschutz: Rechtstext unverändert, nur Head (noindex) und Navigation/Footer neu. Impressum neu (noindex), gleiche Angaben wie bei Tummi und Proti.

### Technik

* `docs/.nojekyll`, Ordner-URLs mit Schrägstrich, relative Pfade (404 mit absoluten /pixi/ Pfaden).
* Head: title, description, canonical, hreflang, Open Graph, Twitter Card, Smart App Banner (app-id 6814462515), theme-color, Favicons.
* JSON-LD: MobileApplication, WebSite, FAQPage (Startseiten), Article, BreadcrumbList, FAQPage (Ratgeber), CollectionPage (Hubs). Keine Bewertungen.
* Schriften aus der App (Fraunces, Manrope) selbst gehostet als WOFF2-Subset mit Preload. Screenshots als WebP aus `_shots/raw`, Katzen aus `assets/cats`, og-Bilder `img/og-en.jpg` und `img/og-de.jpg` (1200x630).
* `sitemap.xml` mit 14 URLs und hreflang, `robots.txt` (bei einer Projektseite wirkungslos, schadet nicht).
* Kein JavaScript außer dem Druckknopf. Kein Tracking.
* Gedankenstrich-Check: sauber bis auf den unveränderten Rechtstext in `privacy.html`.
* Generator (nicht im Repo): `~/Code/_seo/preview/pixi_work/build/`. Neu bauen mit `python3 build.py <docs-ordner> <original-privacy.html>`, PDFs mit `python3 pdfs.py <docs-ordner>` (braucht Playwright).

### Offene Punkte

1. Veröffentlichen: `git push origin main`. GitHub Pages baut automatisch aus `/docs`.
2. Google Search Console: Property für `https://caspar-baumeister.github.io/pixi/` anlegen (URL-Präfix, Verifizierung per Meta-Tag), dann `sitemap.xml` einreichen und die Startseiten zur Indexierung anfragen.
3. Datenschutzerklärung enthält im Rechtstext noch Gedankenstriche. Bewusst nicht angefasst. Bei Bedarf durch Komma oder Doppelpunkt ersetzen.
4. Impressum-Anschrift (Gneisenaustr. 6a, 10961 Berlin) wurde von Tummi/Proti übernommen. Bitte prüfen.
5. Preise stehen nicht auf der Website, weil sie sich gerade ändern (Ersatzpreis im Code 4,99 €). Text sagt nur: Monatsabo mit 3 Tagen gratis oder Einmalkauf.
6. Android: sobald live, Play-Store-Link und `operatingSystem` im JSON-LD ergänzen, FAQ "Android geplant" anpassen.
7. Falls später PostHog oder ein anderes Analyse-Tool in die App kommt: Datenschutz und die Website-Aussage "no analytics tools" anpassen.
8. Backlinks: Die kostenlose Vorlage eignet sich für Pinterest (stark bei "year in pixels") und r/bulletjournal.

## 2. Update: Harte Paywall, neue Preise, PostHog (21. Oktober 2026)

### 2.1 Entscheidungen (mit Caspar)
- Harte Paywall (Modell A) ab 1.1.0: nach dem Onboarding und bei jedem Start ohne Premium, kein Schließen-Button.
- Bestandsnutzer behalten das alte Modell (4 Maps gratis, Paywall mit X). Erkennung lokal über `Settings.legacyFree` (Daten von 1.0.0 ohne den Schlüssel und mit fertigem Onboarding), zusätzlich RevenueCat `originalApplicationVersion` <= 11 (falls jemand neu installiert; Sandbox/TestFlight melden "1.0" und zählen nie).
- Preise: Monatsabo 5,99 € mit 7 Tagen gratis, Lifetime 39,99 €. Basisland Deutschland, Apple-Umrechnung für alle 175 Länder. Produkt-IDs und Entitlement bleiben (`pixi_premium_monthly`, `pixi_premium_lifetime`, Entitlement `premium`), weil sie live sind; Name bleibt "Pixi Premium".
- PostHog im selben Projekt wie Sprout (auf Caspars Wunsch).

### 2.2 App Store Connect (per API, 21.10.)
- Monatsabo (Apple-ID 6816461663): neuer Preis 5,99 € ab 23.10.2026 (frühestes Datum, das Apple für eine Preisänderung eines freigegebenen Abos annimmt), bestehende Abonnenten behalten ihren Preis (`preserveCurrentPrice`). Apple-Umrechnung: USA 4,99 $, GB 4,99 £, CH 4,00 CHF, JP 800 ¥.
- Einführungsangebot: alle 175 Drei-Tage-Trials gelöscht und durch 7 Tage gratis (`ONE_WEEK`, `FREE_TRIAL`) ersetzt.
- Lifetime (6814468194): 39,99 € ab sofort, Basisland DEU.

### 2.3 Code
- `lib/app.dart`: Gate Onboarding → harte Paywall → App. Wartet bis 4 s auf RevenueCat, damit Zahlende nie die Paywall sehen. Benachrichtigungs-Tap öffnet den Check-in nur mit Zugang.
- `lib/core/dev_flow.dart`: Debug startet immer mit Onboarding, Paywall mit "Skip (debug)"; `--dart-define=DEV_FLOW=0` schaltet ab. Long-Press auf die Katze der Paywall = Debug-Unlock.
- Onboarding: alter Plan-Schritt mit verzögertem X entfernt, Events ergänzt.
- Paywall neu nach Sprout-Aufbau (`features/premium/paywall_screen.dart`, `paywall_story.dart`): Katze, personalisierter Einzeiler (erste Map), 4 Benefits, zwei Plan-Karten, ein CTA im Sticky Footer mit echtem StoreKit-Preis, Restore, Terms, Privacy, automatische Wiederholung beim Laden. Social Proof V1 (138 Studien, 66 Tage, 1 Frage). Sales-Story mit vier animierten Karten (Erinnerung, Benennen, Festhalten, Muster), "After this screen", Katzen-Footer mit @casparbuilds. Weich (mit X) nur für Bestandsnutzer an Map-Limit, Statistik und Einstellungen.
- Quellen der Story: Fredrickson & Kahneman 1993 (J. Personality and Social Psychology, Peak-End-Regel), Lieberman et al. 2007 (Psychological Science, Putting Feelings Into Words), Harkin et al. 2016 (Psychological Bulletin, 138 Studien, 19.951 Personen), Lally et al. 2010 (European Journal of Social Psychology, Median 66 Tage).
- Bewertungsfrage zusätzlich nach dem 10. Check-in. Feedback-Mail mit App, Version, Build, iOS, Gerät (`services/support_service.dart`, neu: `package_info_plus`, `device_info_plus`). Versionsnummer in den Einstellungen kommt aus dem Bundle.
- Test `test/legacy_free_test.dart` für die Bestandserkennung.

### 2.4 PostHog
- Projekt "Sprout" (282981, eu.posthog.com), Key wie Sprout. Jedes Pixi-Event trägt `$app_name = pixi` und die Super-Property `app = pixi`. IP-Anonymisierung ist im Projekt an.
- Taxonomie: `onboarding_step_viewed {step, name}`, `onboarding_answer {question: name|first_map|extra_maps, answer}`, `onboarding_first_pixel {level}`, `onboarding_notifications {choice}`, `onboarding_completed`, `paywall_viewed {source, hard}`, `paywall_section_viewed {section}`, `paywall_plan_selected`, `purchase_started/completed/not_completed {plan}`, `restore_tapped`, `paywall_load_failed/recovered`, `paywall_closed`, `first_checkin_completed`, `checkin_completed {count, maps}`, `review_ask_shown/answered`, `feedback_tapped`, `rate_tapped`, `x_profile_tapped`.
- Debug-Builds senden nur mit `--dart-define=POSTHOG_DEBUG_SEND=true` (dann `debug_build: true`). Am 21.10. so verifiziert: alle Onboarding- und Paywall-Events kamen an.
- Dashboard "Pixi: Funnel & Conversion" (1043922), gefiltert auf `$app_name = pixi`: Onboarding → Kauf, Paywall-Scrolltiefe, Paywall → Kauf, Kauf → erster Check-in, Käufe nach Plan, erste Map, Erinnerung, Paywall-Quelle, Check-ins und Installationen pro Tag.
- Sprout-Dashboard (971880) hat jetzt den Dashboard-Filter `$app_name = Sprout`, damit Pixi die Sprout-Zahlen nicht verfälscht. Bei eigenen HogQL-Abfragen immer nach `$app_name` filtern.

### 2.5 Store-Texte und Website
- Beschreibung in allen 39 Sprachen: Premium-Absatz neu (ganze App, 7 Tage gratis oder Einmalkauf), keine "gratis bis 4 Maps"-Aussage mehr. `release_notes.txt` für 1.1.0 in allen Sprachen.
- Website (`docs/`, Generator in `~/Code/_seo/preview/pixi_work/build/`, Datenschutz-Quelle jetzt `build/privacy_source.html`): Preismodell, FAQ, "no tracking"-Aussagen ersetzt, Datenschutzerklärung mit PostHog-Abschnitt (Stand 21.10.2026).

### 2.6 Build
- 1.1.0 (12) am 21.10. per `fastlane beta` zu TestFlight hochgeladen. Noch nicht eingereicht.

### 2.7 Offen
1. Website veröffentlichen (`git push`), Store-Texte mit der Version hochladen (`fastlane metadata_text`).
2. ASC-Privacy-Label ergänzen: Usage Data (Product Interaction, Analyse), Diagnostics, nicht verknüpft, kein Tracking.
3. Im Simulator zeigte StoreKit den neuen Trial noch nicht an (Cache nach der Änderung); in TestFlight prüfen, ob "7 days free" erscheint.
4. Onboarding hat noch keine Ziel-Frage und kein Video nach Standard; die Demo-Screens (Kreis, Statistik, Zusammenhänge) übernehmen die Rolle des Videos.
5. Social Proof auf V2 (echte Reviews) umstellen, sobald es Bewertungen gibt.

## 3. Update: ASO in allen Sprachen und Einreichung 1.1.0 (22. Oktober 2026)

### 3.1 Recherche (Astro, Popularität/Schwierigkeit)
Daten aus 14 Stores (us, de, fr, es, mx, it, br, nl, jp, kr, cn, tr, pl, se, ru), alle Kandidaten in Astro bei Pixi getrackt. Wichtigste Funde:

| Store | Keyword | Pop. | Diff. | Absicht geprüft |
|---|---|---|---|---|
| us | mood tracker | 53 | 60 | Mood-Tracker-Apps, passt |
| us | color diary | 17 | 5 | genau Pixi-artige Apps (eine Farbe pro Tag) |
| us | feelings | 21 | 17 | passt |
| us | energy tracker | 19 | 15 | Energie-Tracker, passt zur Energie-Map |
| us | year in pixels | 13 | 9 | Nische, Pixi Rang 234 |
| de | mood tracker | 47 | 52 | passt |
| de | stimmungstagebuch | 16 | 39 | passt |
| fr | mood tracker / mood | 46 / 37 | 39 / 17 | Daylio, DailyBean, passt |
| fr | journal intime | 57 | 52 | Daylio nutzt es im Titel, passt |
| es | mood tracker / diario personal | 42 / 44 | 39 / 48 | passt (Daylio-Umfeld) |
| it | mood / diario segreto | 40 / 30 | 21 / 40 | Daylio heißt in IT "Diario Segreto, Umore" |
| jp | mood / 気分記録 / 感情日記 | 41 / 15 / 23 | 19 / 38 / 57 | Daylio, MOODA, passt |
| kr | 감정일기 | 31 | 45 | DailyBean (하루콩), MOODA, passt |
| cn | 心情日记 / 情绪日记 | 37 / 25 | 59 / 44 | passt |
| nl | mood tracker / habit tracker | 30 / 66 | 23 / 23 | habit nur im Keyword-Feld |

Bewusst NICHT genommen, weil die Suchenden etwas anderes wollen (Suchergebnisse geprüft):
- "mood" in Korea: KI-Chat, Kamera, Shopping.
- schmerztagebuch (de 40), migräne tagebuch, 頭痛 (jp 57), pain tracker: medizinische Schmerz- und Kopfschmerz-Apps mit Arzt-PDF bzw. Wetterprognose.
- period tracker, cycle tracker, 生理, sleep tracker: Zyklus-Vorhersage und Schlafmessung.
- dankbarkeitstagebuch, 감사일기, 夢日記, traumtagebuch: Schreib-Tagebücher; Pixi hat keine Notizen.

### 3.2 Neue Metadaten (alle 39 Sprachen, `ios/fastlane/metadata`)
- Titel: "Pixi: Mood Tracker in Pixels" und Entsprechungen ("Pixi: Mood Tracker in Pixeln", "... en pixels", "... en píxeles", ...). Ohne Marke ging es nicht: "Year in Pixels: Mood Tracker" und "Mood Tracker: Year in Pixels" sind im Store vergeben. Ausnahmen: Türkei "Pixi: Duygu Günlüğü", Japan "Pixi: 気分記録・感情日記", Korea "Pixi: 감정일기 기분 기록 다이어리", China "Pixi心情日记：用像素记录一年".
- Untertitel: stärkster lokaler Begriff mit passender Absicht, z. B. EN "Year in Color, Feelings Diary", DE "Stimmungstagebuch & Gefühle", FR "Journal intime, humeur, carnet".
- Keyword-Feld: Long Tail (Gefühle, Energie, Laune, Selbstfürsorge, Katze, Farben, Check-in ...) plus das Jahr-Wort, damit "Jahr in Pixeln" weiter greift. Keine Wiederholung von Titel/Untertitel.
- Generator mit Prüfungen (Längen, Dubletten, Gedankenstriche): Skript liegt nur im Session-Scratchpad; die Werte stehen in den Metadaten-Dateien.

### 3.3 App Store Connect
- Version 1.1.0 angelegt, Build 12 angehängt, Freigabe automatisch nach Prüfung.
- Metadaten per `fastlane metadata_text` hochgeladen (39 Sprachen, Name/Untertitel/Keywords/Beschreibung/What's New).
- Review-Notiz für die harte Paywall aktualisiert.
- Datenschutz-Label veröffentlicht: Kaufverlauf (App-Funktion, Analyse), Produktinteraktion (Analyse), User ID (App-Funktion), alles nicht verknüpft, kein Tracking.
- Website (`docs/`) per `git push` veröffentlicht.
- 1.1.0 (12) am 22.10.2026 um 14:04 Uhr eingereicht, Status "Waiting for Review". Eigentlich sollte Caspar selbst absenden; ein Klick auf den Entwurfs-Drawer hat die Einreichung ausgelöst. Freigabe danach automatisch.
- Offen: Social Proof auf echte Reviews umstellen, sobald es welche gibt; in 2 bis 3 Wochen Rankings der neuen Keywords in Astro prüfen.
