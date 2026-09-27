import 'dart:convert';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'pii_sanitizer.dart';

/// Orchestrates file → raw text → sanitized text pipeline.
class DocumentParser {
  /// Extract text from a digital (selectable-text) PDF.
  /// Optionally provide a password for encrypted bank statements.
  Future<String> extractFromDigitalPdf(Uint8List bytes, {String? password}) async {
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: bytes,
        password: password ?? '',
      );
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String fullText = extractor.extractText();
      document.dispose();
      return PiiSanitizer.sanitize(fullText);
    } catch (e) {
      throw DocumentParseException('Failed to parse PDF: $e');
    }
  }

  /// Parse a CSV bank/broker export file.
  Future<String> extractFromCsv(Uint8List bytes) async {
    try {
      final content = utf8.decode(bytes);
      return PiiSanitizer.sanitize(content);
    } catch (e) {
      throw DocumentParseException('Failed to parse CSV: $e');
    }
  }

  /// Determine if a file is a PDF or CSV based on extension.
  bool isPdf(String fileName) =>
      fileName.toLowerCase().endsWith('.pdf');

  bool isCsv(String fileName) =>
      fileName.toLowerCase().endsWith('.csv');

  /// Auto-detect and extract text from a file.
  Future<String> extractFromFile(String fileName, Uint8List bytes, {String? password}) async {
    if (isPdf(fileName)) {
      return extractFromDigitalPdf(bytes, password: password);
    } else if (isCsv(fileName)) {
      return extractFromCsv(bytes);
    } else {
      throw DocumentParseException('Unsupported file type: $fileName');
    }
  }
}

class DocumentParseException implements Exception {
  DocumentParseException(this.message);
  final String message;

  @override
  String toString() => 'DocumentParseException: $message';
}
