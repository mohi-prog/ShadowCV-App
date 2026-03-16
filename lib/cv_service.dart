import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

class CVService {
  static final _storage = FirebaseStorage.instance;
  static final _uuid = Uuid();

  // ─── PDF auswählen ────────────────────────────────────────────────────────
  // Gibt null zurück wenn User abbricht
  static Future<PlatformFile?> pickPDF() async {
    try {
      print('CVService: Starte pickFiles...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData:
            false, // Geändert auf false, um Speicherprobleme auf Xiaomi/Android 13+ zu vermeiden
      );

      if (result == null) {
        print('CVService: User hat Auswahl abgebrochen');
        return null;
      }

      if (result.files.isEmpty) {
        print('CVService: Auswahl leer');
        return null;
      }

      final file = result.files.first;
      print(
        'CVService: Datei ausgewählt: ${file.name}, Pfad: ${file.path}, Größe: ${file.size}',
      );

      // Sicherheitscheck: max 10MB
      if (file.size > 10 * 1024 * 1024) {
        throw Exception('PDF ist zu groß. Maximal 10MB erlaubt.');
      }

      return file;
    } catch (e, stack) {
      print('CVService ERROR in pickPDF: $e');
      print('CVService STACK: $stack');
      rethrow;
    }
  }

  // ─── Text aus PDF extrahieren (on-device) ────────────────────────────────
  // Syncfusion liest den Text direkt aus dem PDF ohne Server
  static Future<String> extractTextFromPDF(PlatformFile file) async {
    try {
      if (file.path == null) throw Exception('Dateipfad nicht verfügbar');

      // Direkter Zugriff auf die Datei ist speicherschonender als readAsBytes
      final File pdfFile = File(file.path!);
      final List<int> bytes = await pdfFile.readAsBytes();

      // PDF öffnen
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);

      // Alle Seiten extrahieren
      final text = extractor.extractText();
      document.dispose();

      // Mindest-Längencheck: leeres PDF abfangen
      if (text.trim().length < 50) {
        // Limit etwas gesenkt für Testzwecke
        throw Exception(
          'PDF scheint zu wenig Text zu enthalten. '
          'Bitte ein PDF mit echtem Text verwenden.',
        );
      }

      return text;
    } catch (e, stack) {
      print('CVService ERROR in extractText: $e');
      print('CVService STACK: $stack');
      rethrow;
    }
  }

  static Future<List<PlatformFile>> pickFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    // Wenn mehr als 3 ausgewählt, nur erste 3 nehmen
    if (result.files.length > 3) {
      return result.files.take(3).toList();
    }

    return result.files;
  }

  // ─── PDF zu Firebase Storage hochladen ───────────────────────────────────
  // Gibt die Download-URL zurück
  static Future<String?> uploadPDFToStorage(PlatformFile file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      if (file.path == null) return null;
      final bytes = await File(file.path!).readAsBytes();

      // Eindeutiger Pfad: users/{uid}/cvs/{uuid}.pdf
      final fileId = _uuid.v4();
      final path = 'users/${user.uid}/cvs/$fileId.pdf';
      final ref = _storage.ref().child(path);

      // Upload
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // Upload-Fehler ist nicht kritisch – Analyse kann trotzdem laufen
      print('CVService.uploadPDF Warnung: $e');
      return null;
    }
  }

  // ─── Kombiniert: PDF auswählen + Text extrahieren ────────────────────────
  // Gibt (file, extractedText) zurück
  // Wirft Exception bei Fehler
  static Future<(PlatformFile file, String text)> pickAndExtract() async {
    final file = await pickPDF();
    if (file == null) throw Exception('Kein PDF ausgewählt');

    final text = await extractTextFromPDF(file);
    return (file, text);
  }
}
