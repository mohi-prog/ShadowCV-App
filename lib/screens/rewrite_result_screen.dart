


import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shadowcv/services/translation_service.dart';
import 'package:shadowcv/services/pdf_export_service.dart';

class RewriteResultScreen extends StatefulWidget {
  final String originalText;
  final String rewrittenText;

  const RewriteResultScreen({
    super.key,
    required this.originalText,
    required this.rewrittenText,
  });

  @override
  State<RewriteResultScreen> createState() => _RewriteResultScreenState();
}

class _RewriteResultScreenState extends State<RewriteResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isExporting = false;
  bool _showAfter = true;
  late String _editableText;
  bool _isEditMode = false;
  late TextEditingController _textEditingController;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _editableText = widget.rewrittenText;
    _textEditingController = TextEditingController(text: _editableText);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  bool get _hasPlaceholders =>
      _editableText.contains('[') && _editableText.contains(']');

  Future<void> _editPlaceholder(String placeholder) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.deepPurpleAccent.withOpacity(0.3)),
        ),
        title: Text(
          AppTranslation.t('Fill details'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.white38),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 2),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppTranslation.t('Cancel'),
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              AppTranslation.t('Save'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _editableText = _editableText.replaceFirst(placeholder, result);
        _textEditingController.text = _editableText;
      });
    }
  }

  Future<void> _exportPDF() async {
    if (_isExporting) return;

    if (_hasPlaceholders) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            AppTranslation.t('Missing information'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            AppTranslation.t('You still have placeholders. Export anyway?'),
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                AppTranslation.t('Back'),
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppTranslation.t('Export'),
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isExporting = true);

    try {
      await PdfExportService.exportCV(_editableText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppTranslation.t('PDF Error')}: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _editableText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslation.t('Copied to clipboard!')),
        backgroundColor: Colors.deepPurpleAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Tiefes Schwarz
      body: Stack(
        children: [
          // Subtiler Hintergrund-Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurpleAccent.withOpacity(0.15),
                // Für den Glow-Effekt müsstest du idealerweise ImageFilter nutzen,
                // aber so bleibt es performant
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  if (_hasPlaceholders && _showAfter) _buildPlaceholderBanner(),
                  const SizedBox(height: 10),
                  _buildToggle(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isEditMode
                              ? Colors.deepPurpleAccent.withOpacity(0.8)
                              : Colors.white.withOpacity(0.05),
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (_isEditMode)
                            BoxShadow(
                              color: Colors.deepPurpleAccent.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            20,
                            20,
                            100,
                          ), // Extra Padding unten für Floating Bar
                          physics: const BouncingScrollPhysics(),
                          child: _buildFormattedCV(
                            _showAfter ? _editableText : widget.originalText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating Action Bar am unteren Rand
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildFloatingActionBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            AppTranslation.t('Rewritten CV'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isEditMode ? Icons.check_circle : Icons.edit_document,
                key: ValueKey(_isEditMode),
                color: _isEditMode ? Colors.greenAccent : Colors.white,
              ),
            ),
            onPressed: () {
              setState(() {
                if (_isEditMode) {
                  _editableText = _textEditingController.text;
                } else {
                  _textEditingController.text = _editableText;
                }
                _isEditMode = !_isEditMode;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleButton(AppTranslation.t('Original'), !_showAfter, () {
            setState(() {
              _showAfter = false;
              _isEditMode = false;
            });
          }),
          _toggleButton(AppTranslation.t('Optimized'), _showAfter, () {
            setState(() => _showAfter = true);
          }),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.deepPurpleAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppTranslation.t('Tap placeholders to fill them'),
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedCV(String text) {
    if (!_showAfter) {
      return Text(
        widget.originalText,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 15,
          height: 1.6,
        ),
      );
    }
    if (_isEditMode) {
      return TextField(
        controller: _textEditingController,
        maxLines: null,
        style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 15),
        decoration: const InputDecoration(border: InputBorder.none),
        onChanged: (val) => _editableText = val,
      );
    }

    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 12);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _renderRichLine(line.trim()),
        );
      }).toList(),
    );
  }

  Widget _renderRichLine(String line) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*|\[.*?\])');
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd)
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      final matchText = match.group(0)!;

      if (matchText.startsWith('**')) {
        spans.add(
          TextSpan(
            text: matchText.replaceAll('**', ''),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => _editPlaceholder(matchText),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  matchText,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      lastEnd = match.end;
    }
    if (lastEnd < line.length)
      spans.add(TextSpan(text: line.substring(lastEnd)));

    // Überprüfe, ob es ein Bullet Point ist, um ihn einzurücken
    bool isBullet =
        line.startsWith('-') || line.startsWith('•') || line.startsWith('*');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isBullet)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8, left: 4),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Colors.deepPurpleAccent.shade200,
            ),
          ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                height: 1.6,
              ),
              children: spans,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyText,
                  icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                  label: Text(
                    AppTranslation.t('Copy'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportPDF,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    AppTranslation.t('Export'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 5,
                    shadowColor: Colors.deepPurpleAccent.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
