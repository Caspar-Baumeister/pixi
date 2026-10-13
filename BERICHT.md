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
