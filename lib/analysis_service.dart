import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'app_config.dart';
import 'cv_analysis.dart';

class AnalysisService {
  static final _uuid = Uuid();

  // ─── Bias-Analyse via Claude API ─────────────────────────────────────────
  static Future<CVAnalysis> analyzeCVBias({
    required String cvText,
    required String fileName,
    String? fileUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Nicht eingeloggt');

    // System-Prompt: Claude soll strukturiertes JSON liefern
    const systemPrompt = '''
Du bist ein Experte für CV-Bias-Analyse und Diskriminierung im Bewerbungsprozess.
Analysiere den gegebenen Lebenslauf auf Diskriminierungspotential und Verbesserungen.

WICHTIG: Antworte NUR mit validem JSON. Kein Text davor oder danach.
Keine Markdown-Backticks. Nur das JSON-Objekt.

JSON-Format:
{
  "biasScore": <Zahl 0-100, 100 = höchstes Risiko>,
  "scoreLabel": "<kurze Begründung des Scores>",
  "issues": [
    {
      "what": "<Was ist das Problem>",
      "why": "<Warum ist es ein Problem für Diskriminierung>",
      "fix": "<Konkrete Verbesserung>",
      "isCritical": <true/false>
    }
  ]
}

Regeln:
- Maximal 10 Issues total
- Genau 3 Issues müssen isCritical: true sein (die wichtigsten)
- Achte auf: Foto, Alter/Geburtsdatum, Geschlecht, Nationalität, Religion, 
  Lücken, Formulierungen, Reihenfolge, persönliche Infos die nicht relevant sind
- Sei konstruktiv und lösungsorientiert
- Sprache: Deutsch
''';

    final userMessage =
        '''
Analysiere diesen Lebenslauf auf Bias und Diskriminierungsrisiko:

---
$cvText
---
''';

    try {
      final response = await http
          .post(
            Uri.parse(AppConfig.claudeApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': AppConfig.claudeApiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': AppConfig.claudeModel,
              'max_tokens': 2000,
              'system': systemPrompt,
              'messages': [
                {'role': 'user', 'content': userMessage},
              ],
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () =>
                throw Exception('Analyse-Timeout. Bitte erneut versuchen.'),
          );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          'API Fehler: ${error['error']?['message'] ?? 'Unbekannter Fehler'}',
        );
      }

      // Claude-Antwort parsen
      final responseBody = jsonDecode(response.body);
      final content = responseBody['content'][0]['text'] as String;
      final analysisData = jsonDecode(content) as Map<String, dynamic>;

      // Issues aufbauen
      final allIssues = (analysisData['issues'] as List<dynamic>)
          .map((e) => CVIssue.fromMap(e as Map<String, dynamic>))
          .toList();

      final criticalIssues = allIssues.where((i) => i.isCritical).toList();

      return CVAnalysis(
        id: _uuid.v4(),
        userId: user.uid,
        fileName: fileName,
        fileUrl: fileUrl,
        biasScore: (analysisData['biasScore'] as num).toInt().clamp(0, 100),
        scoreLabel: analysisData['scoreLabel'] as String,
        issues: allIssues,
        criticalIssues: criticalIssues,
        createdAt: DateTime.now(),
        rawCVText: cvText,
      );
    } on FormatException {
      throw Exception('Ungültige API-Antwort. Bitte erneut versuchen.');
    } catch (e) {
      rethrow;
    }
  }

  // ─── Premium: CV neu schreiben lassen ────────────────────────────────────
  static Future<String> generateOptimizedCV(CVAnalysis analysis) async {
    const systemPrompt = '''
Du bist ein professioneller CV-Schreiber. 
Schreibe den gegebenen Lebenslauf komplett neu:
- Entferne alle diskriminierungsrelevanten Informationen
- Optimiere Formulierungen professionell
- Behalte alle relevanten Fakten bei
- Nutze starke Aktionsverben
- Strukturiere klar und übersichtlich
Antworte mit dem fertigen, verbesserten CV-Text. Kein JSON, nur der CV-Text.
''';

    final response = await http
        .post(
          Uri.parse(AppConfig.claudeApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': AppConfig.claudeApiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': AppConfig.claudeModel,
            'max_tokens': 3000,
            'system': systemPrompt,
            'messages': [
              {
                'role': 'user',
                'content': 'Optimiere diesen CV:\n\n${analysis.rawCVText}',
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw Exception('Fehler beim Optimieren des CVs');
    }

    final responseBody = jsonDecode(response.body);
    return responseBody['content'][0]['text'] as String;
  }

  // ─── Premium: KI-Chat über CV ────────────────────────────────────────────
  // chatHistory = Liste von {'role': 'user'/'assistant', 'content': '...'}
  static Future<String> chatAboutCV({
    required CVAnalysis analysis,
    required List<Map<String, String>> chatHistory,
    required String userMessage,
  }) async {
    final systemPrompt =
        '''
Du bist ein CV-Berater für den User. 
Du hast seinen Lebenslauf analysiert.

Analyse-Ergebnis: ${analysis.biasScore}/100 Bias-Score (${analysis.riskLevel})
Kritische Probleme: ${analysis.criticalIssues.map((i) => i.what).join(', ')}

Original CV:
${analysis.rawCVText}

Beantworte Fragen des Users konkret, hilfreich und auf Deutsch.
Sei freundlich aber direkt.
''';

    // Vollständige Chat-History aufbauen
    final messages = [
      ...chatHistory.map((m) => {'role': m['role']!, 'content': m['content']!}),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http
        .post(
          Uri.parse(AppConfig.claudeApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': AppConfig.claudeApiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': AppConfig.claudeModel,
            'max_tokens': 1000,
            'system': systemPrompt,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Chat-Fehler. Bitte erneut versuchen.');
    }

    final responseBody = jsonDecode(response.body);
    return responseBody['content'][0]['text'] as String;
  }
}
