import * as functions from "firebase-functions";
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI("AIzaSyC2Ep6LwXUHmZsSeKo-9lCH3CzXVtjgRwA");

export const analyzeCV = functions.https.onCall(async (data, context) => {
  const rawText = data.data.rawText;

  if (!rawText || rawText.trim().length < 50) {
    return {
      success: false,
      error: "no_text",
      message: "Kein ausreichender Text gefunden.",
    };
  }

  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `
Du bist ein professioneller CV-Analyst.

Prüfe zuerst, ob der folgende Text ein Lebenslauf / CV ist.

WENN ES KEIN CV IST:
Antworte NUR mit diesem JSON:
{
  "isCV": false,
  "message": "Das hochgeladene Dokument scheint kein Lebenslauf zu sein."
}

WENN ES EIN CV IST:
Analysiere ihn auf Bias, Diskriminierungsrisiken und problematische Inhalte.

Antworte NUR mit validem JSON in diesem Format:
{
  "isCV": true,
  "biasScore": 67,
  "scoreLabel": "Mittleres Risiko",
  "issues": [
    {
      "what": "Geburtsdatum angegeben",
      "why": "Kann Rückschlüsse auf das Alter zulassen.",
      "fix": "Geburtsdatum entfernen, wenn nicht nötig.",
      "isCritical": true
    }
  ]
}

Regeln:
- biasScore von 0 bis 100
- maximal 3 Einträge mit isCritical = true
- achte auf Alter, Foto, Geschlecht, Religion, Familienstand, Nationalität, unnötige persönliche Daten, unklare Formulierungen, Lücken, schwache Struktur
- Antworte NUR mit JSON

TEXT:
${rawText}
`;

  try {
    const result = await model.generateContent(prompt);
    const text = result.response.text();

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      return {
        success: false,
        error: "parse_error",
        message: "KI-Antwort konnte nicht gelesen werden.",
      };
    }

    const parsed = JSON.parse(jsonMatch[0]);

    if (parsed.isCV === false) {
      return {
        success: false,
        error: "not_a_cv",
        message: parsed.message,
      };
    }

    const issues = parsed.issues ?? [];
    const criticalIssues = issues.filter((issue: any) => issue.isCritical === true);

    return {
      success: true,
      biasScore: parsed.biasScore ?? 0,
      scoreLabel: parsed.scoreLabel ?? "Unbekannt",
      issues,
      criticalIssues,
    };
  } catch (error: any) {
    return {
      success: false,
      error: "ai_error",
      message: error.message ?? "Unbekannter Fehler",
    };
  }
});