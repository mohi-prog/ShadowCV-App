import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shadowcv/screens/analysis_result_screen.dart';
import 'package:shadowcv/services/translation_service.dart';

class MyAnalysesScreen extends StatelessWidget {
  const MyAnalysesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppTranslation.t('My Analyses'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontFamily: 'Boldo',
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null
          ? Center(
              child: Text(
                AppTranslation.t('Not logged in'),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Boldo',
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('cvs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Boldo',
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildAnalysisCard(context, data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, Map<String, dynamic> data) {
    final isCV = data['isCV'] ?? true;
    final fileName = data['fileName'] ?? AppTranslation.t('Unknown file');
    final int score = data['score'] ?? data['biasScore'] ?? 0;
    final String scoreLabel = data['scoreLabel'] ?? AppTranslation.t('Unknown');
    final String mode = data['mode'] ?? 'generalReview';
    final String? rawText = data['rawText'];
    final bool hasRawText = rawText != null && rawText.isNotEmpty;
    final createdAt = data['createdAt'];

    String dateText = AppTranslation.t('Unknown date');
    if (createdAt != null && createdAt is Timestamp) {
      final date = createdAt.toDate();
      dateText = '${date.day}.${date.month}.${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCV
              ? [
                  Colors.white.withOpacity(0.05),
                  Colors.deepPurpleAccent.withOpacity(0.06),
                ]
              : [
                  Colors.redAccent.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCV
              ? Colors.white.withOpacity(0.07)
              : Colors.redAccent.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalysisResultScreen(
                  result: data,
                  rawText: rawText, // <-- DER FIX: rawText mitgeben
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                // Oberer Bereich: Icon + Info + Pfeil
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isCV
                            ? Colors.deepPurpleAccent.withOpacity(0.16)
                            : Colors.redAccent.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCV
                            ? Icons.description_rounded
                            : Icons.warning_amber_rounded,
                        color: isCV
                            ? Colors.deepPurpleAccent
                            : Colors.redAccent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Boldo',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dateText,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.48),
                              fontSize: 12,
                              fontFamily: 'Boldo',
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (isCV)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildTag('$score/100', _getScoreColor(score)),
                                _buildTag(scoreLabel, Colors.deepPurpleAccent),
                                _buildModeTag(mode),
                              ],
                            )
                          else
                            _buildNotCVInfo(data),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.22),
                      size: 15,
                    ),
                  ],
                ),

                // Quick Actions (nur für echte CVs mit rawText)
                if (isCV && hasRawText) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withOpacity(0.06),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickAction(
                        icon: Icons.visibility_rounded,
                        label: AppTranslation.t('View'),
                        color: Colors.white54,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalysisResultScreen(
                                result: data,
                                rawText: rawText,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAction(
                        icon: Icons.auto_fix_high_rounded,
                        label: AppTranslation.t('Rewrite'),
                        color: Colors.deepPurpleAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalysisResultScreen(
                                result: data,
                                rawText: rawText,
                              ),
                            ),
                          );
                          // Rewrite wird dort gestartet
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildQuickAction(
                        icon: Icons.psychology_rounded,
                        label: AppTranslation.t('Ask AI'),
                        color: Colors.deepPurpleAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalysisResultScreen(
                                result: data,
                                rawText: rawText,
                              ),
                            ),
                          );
                          // Chat wird dort geöffnet
                        },
                      ),
                    ],
                  ),
                ],

                // Hinweis wenn kein rawText vorhanden
                if (isCV && !hasRawText) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white.withOpacity(0.3),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppTranslation.t(
                              'Older analysis – Chat & Rewrite unavailable',
                            ),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 11,
                              fontFamily: 'Boldo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotCVInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: Text(
            AppTranslation.t('NOT A CV'),
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'Boldo',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          data['message'] ??
              AppTranslation.t('This file was not recognized as a CV.'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 13,
            height: 1.4,
            fontFamily: 'Boldo',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Boldo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              color: Colors.deepPurpleAccent.withOpacity(0.9),
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              AppTranslation.t('No analyses yet'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Boldo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslation.t(
                'Upload your first CV to start building your analysis history.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 13,
                fontFamily: 'Boldo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Boldo',
        ),
      ),
    );
  }

  static Widget _buildModeTag(String mode) {
    String label;
    switch (mode) {
      case 'atsOptimization':
        label = AppTranslation.t('ATS');
        break;
      case 'jobSpecific':
        label = AppTranslation.t('Job-Specific');
        break;
      case 'customPrompt':
        label = AppTranslation.t('Custom');
        break;
      default:
        label = AppTranslation.t('General');
    }
    return _buildTag(label, Colors.deepPurpleAccent);
  }

  static Color _getScoreColor(int score) {
    if (score >= 75) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
