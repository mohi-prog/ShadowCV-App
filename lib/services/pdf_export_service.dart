import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shadowcv/services/translation_service.dart';

class PdfExportService {
  static final PdfColor primary = PdfColor.fromInt(0xFF6200EA); 
  static final PdfColor secondary = PdfColor.fromInt(0xFFF3E5F5); 
  static final PdfColor textDark = PdfColor.fromInt(0xFF1A1A1A);
  static final PdfColor textLight = PdfColor.fromInt(0xFF555555);
  static final PdfColor borderLine = PdfColor.fromInt(0xFFE0E0E0);

  static String _tr(String key, String fallback) {
    try {
      final dynamic v = AppTranslation.t(key);
      return (v is String && v.trim().isNotEmpty) ? v : fallback;
    } catch (_) {
      return fallback;
    }
  }

  // Säubert den Text von Emojis und PDF-inkompatiblen Zeichen
  static String _cleanForPdf(String text) {
    if (text.isEmpty) return "";
    return text
        .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2300}-\u{23FF}]', unicode: true), '')
        .replaceAll('•', '-').replaceAll('●', '-').replaceAll('▪', '-').replaceAll('➔', '->').replaceAll('✓', '')
        .replaceAll('–', '-').replaceAll('—', '-')
        .replaceAll(RegExp(r'[^\x00-\x7FäöüÄÖÜß]'), '')
        .trim();
  }

  static Future<void> exportCV(String content) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateString = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    final fileDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final title = _tr('Curriculum Vitae', 'Curriculum Vitae');
    final copilot = _tr('Optimized by ShadowCV AI', 'Optimized by ShadowCV AI');
    final lines = content.split('\n');

   pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(0),
    footer: (ctx) => _buildFooter(ctx, copilot),
    build: (pw.Context ctx) {
      // 1. Hier definieren wir die Liste namens 'widgets'
      final widgets = <pw.Widget>[];

      // 2. Den Header hinzufügen
      widgets.add(_buildHeader(title, dateString));

      // 3. Den Content mit Padding hinzufügen
      // Wir erstellen eine interne Liste für die Zeilen, damit wir das Seiten-Padding steuern können
      final List<pw.Widget> contentRows = [];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        if (_isHeading(line)) {
          contentRows.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                _buildHeadingWidget(line),
                if (i + 1 < lines.length) _buildAutoLine(lines[i + 1]),
              ],
            ),
          );
          i++; // Überspringe die nächste Zeile, da sie im Block ist
        } else {
          contentRows.add(_buildAutoLine(line));
        }
      }

      // 4. Jetzt packen wir alle Inhaltszeilen mit Abstand zum Rand in die Hauptliste
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: contentRows,
          ),
        ),
      );

      // 5. Hier geben wir 'widgets' zurück - der Name MUSS mit Zeile 1 übereinstimmen
      return widgets;
    },
  ),
);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ShadowCV_$fileDate.pdf',
    );
  }

  // Entscheidet, ob Bulletpoint oder Paragraph
  static pw.Widget _buildAutoLine(String line) {
    final bulletText = _extractBullet(line);
    if (bulletText != null) {
      return _buildBulletWidget(bulletText);
    }
    return _buildParagraphWidget(line);
  }

  static pw.Widget _buildHeader(String title, String date) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(40, 40, 40, 30),
      decoration: pw.BoxDecoration(color: secondary),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title.toUpperCase(),
                  style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: primary, letterSpacing: 1.2)),
              pw.SizedBox(height: 5),
              pw.Text(_tr('Professional Profile', 'Professional Profile'),
                  style: pw.TextStyle(fontSize: 10, color: textLight)),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
                color: PdfColors.white, 
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderLine)),
            child: pw.Text(date, style: pw.TextStyle(fontSize: 10, color: primary, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static bool _isHeading(String text) {
    if (text.startsWith('#')) return true;
    final clean = text.replaceAll(':', '').trim();
    if (clean.length < 3) return false;
    return clean == clean.toUpperCase() && clean.length < 40;
  }

  static String? _extractBullet(String line) {
    final t = line.trim();
    if (t.startsWith('-') || t.startsWith('*') || t.startsWith('•')) {
      return t.substring(1).trim();
    }
    return null;
  }

  static pw.Widget _buildHeadingWidget(String title) {
    final clean = title.replaceAll(RegExp(r'[:#]'), '').trim();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 15, bottom: 8),
      child: pw.Text(clean.toUpperCase(),
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primary)),
    );
  }

  static pw.Widget _buildParagraphWidget(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(fontSize: 10, color: textDark, lineSpacing: 1.5),
          children: _parseMarkdown(_cleanForPdf(text)),
        ),
      ),
    );
  }

  static pw.Widget _buildBulletWidget(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4, left: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 3, height: 3, margin: const pw.EdgeInsets.only(top: 5, right: 8),
              decoration: pw.BoxDecoration(color: primary, shape: pw.BoxShape.circle)),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(fontSize: 10, color: textDark, lineSpacing: 1.4),
                children: _parseMarkdown(_cleanForPdf(text)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.InlineSpan> _parseMarkdown(String text) {
    final parts = text.split('**');
    final List<pw.InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(pw.TextSpan(
          text: parts[i],
          style: pw.TextStyle(fontWeight: i % 2 != 0 ? pw.FontWeight.bold : pw.FontWeight.normal)));
    }
    return spans;
  }

  static pw.Widget _buildFooter(pw.Context ctx, String copilotText) {
    return pw.Container(
      margin: const pw.EdgeInsets.fromLTRB(40, 0, 40, 20),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: borderLine, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(copilotText, style: pw.TextStyle(fontSize: 8, color: textLight)),
          pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: textLight)),
        ],
      ),
    );
  }
}