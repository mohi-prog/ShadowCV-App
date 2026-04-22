import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Einzelnes Problem im CV ──────────────────────────────────────────────────
class CVIssue {
  final String what; // ❌ Was ist falsch
  final String why; // 💡 Warum ist es ein Problem
  final String fix; // ✅ Wie verbessern
  final bool isCritical; // Top 3 kritische Fehler

  const CVIssue({
    required this.what,
    required this.why,
    required this.fix,
    this.isCritical = false,
  });

  // Firestore → Objekt
  factory CVIssue.fromMap(Map<String, dynamic> map) {
    return CVIssue(
      what: map['what'] ?? '',
      why: map['why'] ?? '',
      fix: map['fix'] ?? '',
      isCritical: map['isCritical'] ?? false,
    );
  }

  // Objekt → Firestore
  Map<String, dynamic> toMap() => {
    'what': what,
    'why': why,
    'fix': fix,
    'isCritical': isCritical,
  };
}

// ─── Gesamt-Analyse eines CVs ─────────────────────────────────────────────────
class CVAnalysis {
  final String id;
  final String userId;
  final String fileName;
  final String? fileUrl; // Firebase Storage URL
  final int biasScore; // 0–100 (100 = höchstes Diskriminierungsrisiko)
  final String scoreLabel; // z.B. "Mittleres Risiko"
  final List<CVIssue> issues;
  final List<CVIssue> criticalIssues; // Top 3
  final String? optimizedCV; // Premium: neu geschriebener CV Text
  final DateTime createdAt;
  final String rawCVText; // Original extrahierter Text (für KI-Chat)

  const CVAnalysis({
    required this.id,
    required this.userId,
    required this.fileName,
    this.fileUrl,
    required this.biasScore,
    required this.scoreLabel,
    required this.issues,
    required this.criticalIssues,
    this.optimizedCV,
    required this.createdAt,
    required this.rawCVText,
  });

  // Gibt Risikolevel als lesbaren Text zurück
  String get riskLevel {
    if (biasScore >= 70) return 'Hohes Risiko';
    if (biasScore >= 40) return 'Mittleres Risiko';
    return 'Geringes Risiko';
  }

  // Farbe abhängig vom Score
  String get scoreColor {
    if (biasScore >= 70) return 'red';
    if (biasScore >= 40) return 'orange';
    return 'green';
  }

  // Firestore → Objekt
  factory CVAnalysis.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CVAnalysis(
      id: doc.id,
      userId: data['userId'] ?? '',
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'],
      biasScore: data['biasScore'] ?? 0,
      scoreLabel: data['scoreLabel'] ?? '',
      issues: (data['issues'] as List<dynamic>? ?? [])
          .map((e) => CVIssue.fromMap(e as Map<String, dynamic>))
          .toList(),
      criticalIssues: (data['criticalIssues'] as List<dynamic>? ?? [])
          .map((e) => CVIssue.fromMap(e as Map<String, dynamic>))
          .toList(),
      optimizedCV: data['optimizedCV'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rawCVText: data['rawCVText'] ?? '',
    );
  }

  // Objekt → Firestore
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'biasScore': biasScore,
    'scoreLabel': scoreLabel,
    'issues': issues.map((e) => e.toMap()).toList(),
    'criticalIssues': criticalIssues.map((e) => e.toMap()).toList(),
    'optimizedCV': optimizedCV,
    'createdAt': Timestamp.fromDate(createdAt),
    'rawCVText': rawCVText,
  };
}
