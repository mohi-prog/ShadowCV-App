# Plan: Behebung des App-Restarts auf Xiaomi 13

Das Problem liegt höchstwahrscheinlich daran, dass Xiaomi (MIUI/HyperOS) die App im Hintergrund aggressiv beendet, sobald der Datei-Picker geöffnet wird ("Don't keep activities" Verhalten). Wenn der Nutzer eine Datei auswählt, startet die App komplett neu, landet im `AuthWrapper` und zeigt erneut den `SplashScreen`.

## Analyse
*   **Xiaomi 13 Aggressives RAM-Management:** Das System killt die Haupt-Activity der Flutter-App, um Ressourcen für den Datei-Picker freizugeben.
*   **Navigation-Logic:** In `main.dart` führt jede Statusänderung (oder ein App-Neustart) dazu, dass der `AuthWrapper` den `SplashScreen` als `initialData` oder während des Ladens anzeigt.
*   **Fehlende Persistenz:** Da die App neu startet, geht der Status `_isAnalyzing` verloren.

## Empfohlene Maßnahmen

### 1. Navigation in `main.dart` stabilisieren
Der `AuthWrapper` in `lib/main.dart` sollte den `SplashScreen` nicht bei jedem Rebuild oder Re-Initialisierung erzwingen, wenn der User bereits eingeloggt ist.
*   Anpassung des `StreamBuilder` und `FutureBuilder`, um weniger sprunghaft zwischen Screens zu wechseln.

### 2. Android Lifecycle Optimierung
In `android/app/src/main/AndroidManifest.xml` sicherstellen, dass die Activity-Konfiguration stabil ist.
*   Prüfung von `android:launchMode`.

### 3. FilePicker Result Handling
Falls die App wirklich gekillt wird, bietet das `file_picker` Plugin (oder alternative Plugins) Mechanismen an, um das Ergebnis nach einem Restart abzurufen.

## Nächste Schritte
1.  **main.dart** so umbauen, dass der `SplashScreen` nur beim echten Erststart erscheint.
2.  **home_screen.dart** so vorbereiten, dass ein potenzieller App-Restart den Analyse-Flow nicht komplett bricht.
3.  **AndroidManifest.xml** prüfen, ob `singleTop` oder andere Flags das Verhalten beeinflussen.

---
Datei-Referenz: `c:\FlutterProjects\shadowcv\lib\main.dart`, `c:\FlutterProjects\shadowcv\lib\home_screen.dart`
