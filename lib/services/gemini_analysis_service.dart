// gemini_analysis_service.dart
// Änderungen: customPrompt Mode komplett neu gebaut
// - eigenes JSON-Format: customResponse + keyPoints + actionItems
// - analyzeCVText gibt bei customPrompt eine andere Map-Struktur zurück
// - Prompt ist jetzt rein fragebasiert, kein erzwungener Score

import 'dart:convert';
import 'package:http/http.dart' as http;

enum AnalysisMode { generalReview, atsOptimization, jobSpecific, customPrompt }

class GeminiAnalysisService {
  static const String _apiKey =
      'REDACTED_GROQ_KEY';
  static const String _url = 'https://api.groq.com/openai/v1/chat/completions';

  // ==================== ANALYSE ====================

  static Future<Map<String, dynamic>> analyzeCVText(
    String rawText, {
    AnalysisMode mode = AnalysisMode.generalReview,
    String? customPrompt,
    String? targetJob,
    String? userJob,
    String? userGoal,
    String? language,
  }) async {
    if (rawText.trim().length < 50) {
      return {
        'isCV': false,
        'message': 'The uploaded document does not contain enough text.',
      };
    }

    final trimmedText = rawText.length > 6000
        ? '${rawText.substring(0, 6000)}\n\n[... CV text truncated for processing ...]'
        : rawText;

    final modePrompt = _buildPrompt(
      trimmedText,
      mode,
      customPrompt,
      targetJob,
      userJob,
      userGoal,
      language,
    );

    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': modePrompt},
              ],
              'temperature': 0.3,
              'max_tokens': 2500,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () =>
                throw Exception('Request timed out. Please try again.'),
          );

      if (response.statusCode != 200) {
        throw Exception(
            'API Error (${response.statusCode}): ${response.body}');
      }

      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] ?? '';
      final parsed = _extractJson(text);

      if (parsed == null) {
        throw Exception('AI returned invalid format. Please try again.');
      }

      // ─── isCV=false: Dokument ist kein CV ───
      if (parsed['isCV'] == false) {
        return {
          'isCV': false,
          'message': parsed['message'] ?? 'This does not appear to be a CV.',
          'documentType': parsed['documentType'] ?? 'Unknown',
        };
      }

      // ─── customPrompt: eigene Map-Struktur ───
      // Die UI (analysis_result_screen) muss mode=='customPrompt' separat rendern!
      if (mode == AnalysisMode.customPrompt) {
        return {
          'isCV': true,
          'mode': mode.name,
          // Direkte Antwort auf die User-Frage als Fließtext
          'customResponse': parsed['customResponse'] ?? '',
          // Strukturierte Kernpunkte (optional, kann leer sein)
          'keyPoints': _toStringList(parsed['keyPoints']),
          // Konkrete Handlungsempfehlungen (optional)
          'actionItems': _toStringList(parsed['actionItems']),
          // userPrompt zurückgeben, damit die UI die Frage anzeigen kann
          'userPrompt': customPrompt ?? '',
        };
      }

      // ─── Standard-Modi: bewährte Struktur ───
      return {
        'isCV': true,
        'mode': mode.name,
        'score': _clampScore(parsed['score']),
        'scoreLabel': parsed['scoreLabel'] ??
            _getScoreLabel(_clampScore(parsed['score'])),
        'summary': parsed['summary'] ?? '',
        'strengths': _toStringList(parsed['strengths']),
        'weaknesses': _toStringList(parsed['weaknesses']),
        'suggestions': parsed['suggestions'] ?? [],
        'topPriorities': _toStringList(parsed['topPriorities']),
      };
    } catch (e) {
      throw Exception('Analysis failed: $e');
    }
  }

  // ==================== PROMPTS ====================

  static String _buildPrompt(
    String rawText,
    AnalysisMode mode,
    String? customPrompt,
    String? targetJob,
    String? userJob,
    String? userGoal,
    String? language,
  ) {
    final lang = language ?? 'English';

    String userContext = '';
    if ((userJob != null && userJob.isNotEmpty) ||
        (userGoal != null && userGoal.isNotEmpty)) {
      userContext = '''
=== USER CONTEXT ===
- Current profession: ${userJob ?? 'Unknown'}
- Career goal: ${userGoal ?? 'Unknown'}
Use this context to make every answer directly relevant to this person's career path.
''';
    }

    // ─── Wiederverwendbarer CV-Check Block ───
    final cvCheck = '''
STEP 1: Is this a real CV/Resume?

A real CV contains MOST of these:
✓ Name + contact info
✓ Work experience with companies and dates
✓ Education
✓ Skills

These are NOT CVs → reject them:
✗ Invoices, contracts, articles, job postings, cover letters (alone), random text

Be strict: if less than 70% confident → reject.

If NOT a CV, respond ONLY with:
{
  "isCV": false,
  "documentType": "specific type e.g. Invoice / Job Posting",
  "message": "In $lang: 1) What this document is. 2) Why it's not a CV. 3) What to upload instead."
}

If YES → continue with your task below.
''';

    // ─── Standard JSON Format für alle anderen Modi ───
    const standardJsonFormat = '''
{
  "isCV": true,
  "score": 65,
  "scoreLabel": "Good",
  "summary": "2-3 sentences referencing specific CV content.",
  "strengths": ["Specific strength referencing actual CV content"],
  "weaknesses": ["Specific weakness referencing actual CV content"],
  "suggestions": [
    {
      "title": "Short actionable title",
      "description": "Exact steps. Reference specific sections/lines. Give before/after examples."
    }
  ],
  "topPriorities": ["The single most impactful change. Be concrete."]
}''';

    final strictStandardRules = '''
=== STRICT RULES ===
- Score 0-100. Honest: average CVs get 40-60, not 70+
- scoreLabel: "Poor" (0-30), "Fair" (31-50), "Good" (51-75), "Very Good" (76-90), "Excellent" (91-100)
- NEVER generic advice. ALWAYS reference specific CV content.
- 3-5 strengths, 3-5 weaknesses, 3-5 suggestions, 2-3 top priorities
- Write ALL text in $lang
- Respond ONLY with valid JSON
''';

    // ==================== customPrompt: komplett anders ====================
    if (mode == AnalysisMode.customPrompt) {
      final question = (customPrompt != null && customPrompt.trim().isNotEmpty)
          ? customPrompt.trim()
          : 'Give general feedback on this CV.';

      return '''
You are an elite CV consultant and career expert.
$userContext
$cvCheck

=== THE USER'S SPECIFIC QUESTION ===
"$question"

=== YOUR MISSION ===
Answer EXACTLY and ONLY what the user asked. Do not give a generic CV analysis.

Rules for your answer:
1. Stay laser-focused on the question: "$question"
2. Base EVERY point on actual content found in the CV
3. Quote or reference specific sections, job titles, companies, skills from the CV
4. Be concrete and direct – no vague advice
5. If the question has no clear answer from the CV, say what's missing and why
6. Write entirely in $lang

=== JSON FORMAT (respond ONLY with this) ===
{
  "isCV": true,
  "customResponse": "Your direct, detailed answer to the question in $lang. This is the main response – write it as clear flowing text (not bullet points). Reference specific CV content. Aim for 100-250 words.",
  "keyPoints": [
    "Concrete key finding or insight directly relevant to the question (reference CV content)",
    "Another key point – minimum 2, maximum 5 points"
  ],
  "actionItems": [
    "Concrete action step the user can take TODAY based on your answer",
    "Another action step – minimum 1, maximum 4 steps"
  ]
}

Important: 
- keyPoints and actionItems CAN be empty arrays [] if the question is purely informational
- customResponse must ALWAYS be filled
- Do NOT add score, strengths, weaknesses – those are not asked for
- Respond ONLY with valid JSON. No text outside JSON.

=== CV TEXT ===
$rawText
''';
    }

    // ==================== Alle anderen Modi =====================

    switch (mode) {
      case AnalysisMode.generalReview:
        return '''
You are a senior CV consultant with 15 years of experience in HR and recruiting.
$userContext
$cvCheck

=== YOUR TASK: DEEP GENERAL CV REVIEW ===
Analyze across:
1. STRUCTURE & LAYOUT: Logical order? Right length?
2. CONTENT QUALITY: Achievements quantified? Action verbs?
3. PROFESSIONAL IMPACT: Would a recruiter want to interview this person?
4. LANGUAGE & TONE: Professional? Grammar issues? Filler words?
5. COMPLETENESS: Missing sections?
6. RED FLAGS: Gaps, inconsistencies, outdated info?

Reference SPECIFIC content from the CV for every point.

$strictStandardRules
$standardJsonFormat

=== CV TEXT ===
$rawText
''';

      case AnalysisMode.atsOptimization:
        return '''
You are an ATS expert who built ATS software for Fortune 500 companies.
$userContext
$cvCheck

=== YOUR TASK: ATS COMPATIBILITY DEEP SCAN ===
Check:
1. PARSING ISSUES: Tables, columns, non-standard headers?
2. KEYWORD DENSITY: What keywords are present? What's missing?
3. FORMAT COMPLIANCE: Consistent dates? Standard job titles?
4. SECTION STRUCTURE: Standard ATS-friendly order?
5. SKILL MATCHING: Hard and soft skills found. What's missing?

Reference SPECIFIC lines, sections, and missing keywords.

$strictStandardRules
$standardJsonFormat

=== CV TEXT ===
$rawText
''';

      case AnalysisMode.jobSpecific:
        final job = targetJob ?? 'General position';
        return '''
You are a hiring manager actively recruiting for: "$job". You've reviewed 200+ CVs for this role.
$userContext
$cvCheck

=== YOUR TASK: JOB-SPECIFIC ANALYSIS FOR "$job" ===
1. ROLE FIT: How well does this candidate match "$job"?
2. MISSING MUST-HAVES: Top 5 required skills/experiences. Which are missing?
3. RELEVANT EXPERIENCE: What's relevant vs. irrelevant?
4. KEYWORD GAPS: What keywords are missing for "$job"?
5. TAILORING ADVICE: Rewrite specific bullet points to target "$job".

Reference "$job" in every suggestion. No generic advice.

$strictStandardRules
$standardJsonFormat

=== CV TEXT ===
$rawText
''';

      // customPrompt wird oben behandelt, dieser Fall wird nie erreicht
      case AnalysisMode.customPrompt:
        return '';
    }
  }

  // ==================== CHAT ====================

  static Future<String> chatWithCV({
    required String rawText,
    required Map<String, dynamic> analysisResult,
    required List<Map<String, String>> messages,
    String? language,
  }) async {
    final lang = language ?? 'English';
    final mode = analysisResult['mode'] ?? 'generalReview';
    final score = analysisResult['score'] ?? 0;
    final strengths = analysisResult['strengths'] ?? [];
    final weaknesses = analysisResult['weaknesses'] ?? [];
    final priorities = analysisResult['topPriorities'] ?? [];

    // Bei customPrompt: Chat-Kontext anders aufbauen
    final customContext = mode == 'customPrompt'
        ? '''
- Analysis Type: Custom Question
- User Asked: "${analysisResult['userPrompt'] ?? ''}"
- AI Response Summary: "${analysisResult['customResponse'] ?? ''}"
- Key Points: ${(analysisResult['keyPoints'] as List?)?.join(', ') ?? ''}
'''
        : '''
- Overall Score: $score/100
- Analysis Mode: $mode
- Key Strengths: ${strengths.join(', ')}
- Key Weaknesses: ${weaknesses.join(', ')}
- Top Priorities: ${priorities.join(', ')}
''';

    final systemPrompt = '''
You are an expert CV consultant with deep knowledge of hiring, ATS systems, and career development.

=== CV CONTEXT ===
$rawText

=== ANALYSIS ALREADY DONE ===
$customContext

=== YOUR ROLE ===
- Answer questions specifically about THIS CV and THIS analysis
- Be concrete and reference actual content from the CV
- Give actionable, specific advice – never vague
- If asked for rewrites, provide actual example text
- Be encouraging but honest
- Keep responses concise (max 4-5 sentences unless asked for more)
- ALWAYS respond in $lang
''';

    final conversationMessages = messages
        .where((m) => !(m['role'] == 'assistant' && messages.indexOf(m) == 0))
        .map((m) => {'role': m['role']!, 'content': m['content']!})
        .toList();

    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.1-8b-instant',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                ...conversationMessages,
              ],
              'temperature': 0.5,
              'max_tokens': 800,
            }),
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw Exception('Chat request timed out.'),
          );

      if (response.statusCode != 200) {
        throw Exception('Groq Error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }

  // ==================== INTERVIEW PREP ====================

  static Future<Map<String, dynamic>> generateInterviewPrep({
    required String rawText,
    required String targetJob,
    String? userJob,
    String? userGoal,
    String? language,
  }) async {
    final lang = language ?? 'English';
    final trimmedText = rawText.length > 6000
        ? '${rawText.substring(0, 6000)}\n\n[... CV text truncated ...]'
        : rawText;

    final prompt = '''
You are an expert interview coach with 20 years of experience preparing candidates for top companies.

=== YOUR TASK ===
Generate exactly 10 highly personalized interview questions for this candidate applying for: "$targetJob"
Questions MUST be based on actual CV content – reference real job titles, companies, skills, experiences.

=== CATEGORIES ===
- "Behavioral" (2-3): based on past experiences from CV
- "Technical" (2-3): based on skills listed in CV
- "Motivational" (2): why this role, why this company
- "Situational" (2-3): hypothetical scenarios relevant to the role

=== FOR EACH QUESTION ===
1. Reference something SPECIFIC from the CV
2. STAR method example answer based on CV facts
3. One "Pro Tip"

=== STRICT RULES ===
- No generic questions without CV personalization
- Write everything in $lang
- Respond ONLY with valid JSON

=== JSON FORMAT ===
{
  "targetJob": "$targetJob",
  "totalQuestions": 10,
  "questions": [
    {
      "id": 1,
      "category": "Behavioral",
      "question": "Personalized question referencing specific CV content",
      "whyAsked": "Brief explanation",
      "exampleAnswer": "STAR method answer using CV facts",
      "proTip": "One specific tip"
    }
  ]
}

=== CANDIDATE CV ===
$trimmedText
''';

    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.4,
              'max_tokens': 4000,
            }),
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () =>
                throw Exception('Request timed out. Please try again.'),
          );

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] ?? '';
      final parsed = _extractJson(text);
      if (parsed == null) {
        throw Exception('Invalid response format. Please try again.');
      }
      return parsed;
    } catch (e) {
      throw Exception('Interview prep failed: $e');
    }
  }

  // ==================== COVER LETTER ====================

  static Future<String> generateCoverLetter({
    required String rawText,
    required String targetJob,
    required String tone,
    String? userJob,
    String? userGoal,
    String? language,
  }) async {
    final lang = language ?? 'English';
    final trimmedText = rawText.length > 6000
        ? '${rawText.substring(0, 6000)}\n\n[... CV text truncated ...]'
        : rawText;

    final prompt = '''
You are an expert cover letter writer with 20 years of experience.

=== YOUR TASK ===
Write a highly personalized, professional cover letter for this candidate applying for: "$targetJob"

=== TONE ===
"$tone":
- "Professional": formal, structured, confident
- "Formal": very formal, conservative, respectful
- "Creative": engaging, unique, memorable

=== STRICT RULES ===
1. NEVER invent information not in the CV
2. Reference SPECIFIC details (companies, achievements, skills, years)
3. Structure: Opening Hook → Why this role → What you bring → Call to action
4. Exactly 3-4 paragraphs, max 350 words
5. Never start with "I am writing to apply for..."
6. No clichés ("team player", "hardworking", "passionate")
7. Use placeholders: [Company Name], [Hiring Manager Name] if unknown
8. Write ONLY the cover letter text – no subject line, no explanations
9. Write in $lang

=== CANDIDATE CV ===
$trimmedText
''';

    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.5,
              'max_tokens': 1500,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () =>
                throw Exception('Request timed out. Please try again.'),
          );

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } catch (e) {
      throw Exception('Cover letter generation failed: $e');
    }
  }

  // ==================== SALARY INSIGHTS ====================

  // rawText ist jetzt nullable:
// - null  → rein marktbasierte Analyse (kein CV vorhanden)
// - String → CV-gestützte Analyse wie bisher
static Future<Map<String, dynamic>> generateSalaryInsights({
  required String? rawText,         // <-- war: required String rawText
  required String targetJob,
  required String country,
  String? userJob,
  String? language,
}) async {
  final lang = language ?? 'English';
  final hasCV = rawText != null && rawText.trim().length > 50;

  // CV-Block nur einfügen wenn tatsächlich vorhanden
  final cvSection = hasCV
      ? '''
=== CANDIDATE CV ===
${rawText.length > 6000 ? '${rawText.substring(0, 6000)}\n\n[... CV text truncated ...]' : rawText}
'''
      : '''
=== NOTE ===
No CV was provided. Base your analysis purely on typical market data for "$targetJob" in "$country".
For experienceYears use a typical mid-level estimate (e.g. 3-5 years).
For candidateLevel use "Market Average".
For salaryBoosts list general skills that typically boost salary for this role.
For salaryLimits list common gaps that limit salary for this role.
''';

  // Analyse-Anweisung ändert sich je nach CV-Verfügbarkeit
  final analysisInstruction = hasCV
      ? '''
Analyze this CV and provide realistic salary insights for: "$targetJob" in "$country"

Estimate salary based on:
- Years of experience found in CV
- Skills and technologies listed
- Education level
- Career progression shown
- Industry and location ($country)
'''
      : '''
Provide realistic market salary insights for: "$targetJob" in "$country"

Since no CV was provided:
- Use typical market ranges for this role in $country
- Describe what generally boosts or limits salary for this role
- Give actionable tips to maximize earnings in this field
''';

  final prompt = '''
You are a senior compensation analyst and HR expert with deep knowledge of global salary markets.

=== YOUR TASK ===
$analysisInstruction

=== STRICT RULES ===
- Be realistic and specific to $country market
- Use $country currency
- Write everything in $lang
- Respond ONLY with valid JSON

=== JSON FORMAT ===
{
  "targetJob": "$targetJob",
  "country": "$country",
  "currency": "€ or \$ or £ etc based on country",
  "salaryMin": 45000,
  "salaryMid": 60000,
  "salaryMax": 75000,
  "marketAverage": 58000,
  "candidateLevel": "Mid-Level",
  "experienceYears": 4,
  "salaryBoosts": [
    "Skill or experience that increases salary for this role"
  ],
  "salaryLimits": [
    "Common gap or weakness that limits salary for this role"
  ],
  "topTips": [
    "Concrete actionable tip to increase earning potential"
  ],
  "marketComparison": "above/below/at market",
  "summary": "2-3 sentences summarizing the salary analysis"
}

$cvSection
''';

  try {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 2000,
      }),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Request timed out. Please try again.'),
    );

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['choices'][0]['message']['content'] ?? '';
    final parsed = _extractJson(text);

    if (parsed == null) {
      throw Exception('Invalid response format. Please try again.');
    }

    return parsed;
  } catch (e) {
    throw Exception('Salary insights failed: $e');
  }
}
/// Gesamt-Feedback nach Abschluss der Simulation.
/// Nimmt alle Evaluationen und generiert ein konsolidiertes Coaching-Summary.
static Future<String> generateInterviewSummary({
  required List<Map<String, dynamic>> evaluations,
  required String targetJob,
  String? language,
}) async {
  final lang = language ?? 'English';

  // Kompaktes Q&A Zusammenfassung für den Prompt
  final qaSummary = evaluations.asMap().entries.map((e) {
    final i = e.key + 1;
    final eval = e.value;
    return '''
Q$i [${eval['category']}] Score: ${eval['score']}/10
Question: ${eval['question']}
Answer summary: ${(eval['answer'] as String).substring(0, (eval['answer'] as String).length.clamp(0, 200))}
''';
  }).join('\n');

  final avgScore = evaluations.isEmpty
      ? 0.0
      : evaluations
              .map((e) => (e['score'] as int?) ?? 0)
              .reduce((a, b) => a + b) /
          evaluations.length;

  final prompt = '''
You are a senior interview coach reviewing a mock interview session.

=== SIMULATION DATA ===
Job: "$targetJob"
Average Score: ${avgScore.toStringAsFixed(1)}/10
Total Questions: ${evaluations.length}

=== QUESTION PERFORMANCE ===
$qaSummary

=== YOUR TASK ===
Write a concise overall performance review in $lang using this structure:

**Overall Performance**
2-3 sentences on how the candidate performed overall. Reference the average score and general pattern.

**🏆 Biggest Strengths**
2-3 patterns you noticed across their best answers.

**🚨 Critical Areas to Improve**
2-3 recurring weaknesses across their answers. Be specific.

**📚 Practice Recommendations**
3 concrete actions they should take before a real interview for "$targetJob".

Keep it under 300 words. Be direct and encouraging.
''';

  try {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
        'max_tokens': 800,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] ?? '';
  } catch (e) {
    throw Exception('Summary generation failed: $e');
  }
}
  // ==================== REWRITE ====================

  static Future<String> rewriteCV(
    String rawText, {
    required Map<String, dynamic> analysisResult,
    String? userJob,
    String? userGoal,
    String? language,
  }) async {
    final lang = language ?? 'English';
    final weaknesses = analysisResult['weaknesses'] ?? [];
    final suggestions = analysisResult['suggestions'] ?? [];
    final topPriorities = analysisResult['topPriorities'] ?? [];
    final strengths = analysisResult['strengths'] ?? [];
    final mode = analysisResult['mode'] ?? 'generalReview';

    String issuesList = '';
    if (topPriorities.isNotEmpty) {
      issuesList += '=== TOP PRIORITIES TO FIX ===\n';
      for (final p in topPriorities) issuesList += '→ $p\n';
      issuesList += '\n';
    }
    if (weaknesses.isNotEmpty) {
      issuesList += '=== WEAKNESSES TO ELIMINATE ===\n';
      for (final w in weaknesses) issuesList += '→ $w\n';
      issuesList += '\n';
    }
    if (suggestions.isNotEmpty) {
      issuesList += '=== SUGGESTIONS TO APPLY ===\n';
      for (final s in suggestions) {
        issuesList += s is Map
            ? '→ ${s['title']}: ${s['description']}\n'
            : '→ $s\n';
      }
      issuesList += '\n';
    }
    if (strengths.isNotEmpty) {
      issuesList += '=== STRENGTHS TO KEEP & ENHANCE ===\n';
      for (final s in strengths) issuesList += '✓ $s\n';
    }

    // Bei customPrompt: keyPoints und actionItems als Kontext nutzen
    if (mode == 'customPrompt') {
      final keyPoints = analysisResult['keyPoints'] ?? [];
      final actionItems = analysisResult['actionItems'] ?? [];
      if (keyPoints.isNotEmpty) {
        issuesList += '=== KEY INSIGHTS FROM CUSTOM ANALYSIS ===\n';
        for (final k in keyPoints) issuesList += '→ $k\n';
        issuesList += '\n';
      }
      if (actionItems.isNotEmpty) {
        issuesList += '=== ACTION ITEMS TO APPLY ===\n';
        for (final a in actionItems) issuesList += '→ $a\n';
      }
    }

    String userContext = '';
    if (userJob != null && userJob.isNotEmpty) {
      userContext += '- Current/Target profession: $userJob\n';
    }
    if (userGoal != null && userGoal.isNotEmpty) {
      userContext += '- Career goal: $userGoal\n';
    }

    final trimmedText = rawText.length > 6000
        ? '${rawText.substring(0, 6000)}\n\n[... CV text truncated ...]'
        : rawText;

  final prompt = '''
You are an expert CV Optimizer. 
Your goal: Transform a boring CV into a high-impact, professional document WITHOUT inventing facts.

=== REWRITING STRATEGY ===
1. VERBS: Replace weak verbs (helped, worked, did) with power verbs (Spearheaded, Orchestrated, Optimized, Developed).
2. IMPACT: If a sentence is "I sold cars", rewrite it to "Driven sales performance by managing customer relations and vehicle presentations". 
3. PLACEHOLDERS: If you want to show an achievement but don't have a number, use: "[ADD: % or number]". 
   Example: "Increased efficiency by [ADD: %] through process automation."
4. NO HALLUCINATIONS: Do not add companies or dates that aren't there.

=== STRUCTURE ===
# [NAME]
[Email] | [Phone] | [Location]

## PROFESSIONAL SUMMARY
(Write a compelling 3-line summary that highlights the person's unique value)

## EXPERIENCE
**[Job Title]** | **[Company]**
*[Dates]*
- Bullet points...

## EDUCATION
...
## SKILLS
...

Write in $lang. Use ONLY standard hyphens (-) for bullets.
ORIGINAL CV:
$trimmedText
''';
    try {
      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.1,
              'max_tokens': 4000,
            }),
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () =>
                throw Exception('Rewrite timed out. Please try again.'),
          );

      if (response.statusCode != 200) {
        throw Exception('Groq Error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? '';
    } catch (e) {
      throw Exception('Rewrite failed: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  static Map<String, dynamic>? _extractJson(String text) {
    // Versuch 1: Direkt parsen
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {}

    // Versuch 2: Aus Markdown Code Block
    try {
      final codeBlock =
          RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
      if (codeBlock != null) {
        return jsonDecode(codeBlock.group(1)!.trim()) as Map<String, dynamic>;
      }
    } catch (_) {}

    // Versuch 3: Erstes { bis letztes }
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        return jsonDecode(text.substring(start, end + 1))
            as Map<String, dynamic>;
      }
    } catch (_) {}

    return null;
  }

  static int _clampScore(dynamic score) {
    if (score == null) return 0;
    final s = score is int ? score : int.tryParse(score.toString()) ?? 0;
    return s.clamp(0, 100);
  }

  static String _getScoreLabel(int score) {
    if (score <= 30) return 'Poor';
    if (score <= 50) return 'Fair';
    if (score <= 75) return 'Good';
    if (score <= 90) return 'Very Good';
    return 'Excellent';
  }

  static List<String> _toStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }
}