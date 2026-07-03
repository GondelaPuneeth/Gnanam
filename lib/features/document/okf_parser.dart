import 'dart:io';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Parses various document formats (PDF, DOCX, TXT) into the 
/// Open Knowledge Format (OKF) - which is Markdown with YAML frontmatter.
class OKFParser {
  
  /// Parses a file into an OKF formatted Markdown string.
  Future<String> parseFileToOKF(File file) async {
    final extension = p.extension(file.path).toLowerCase();
    final filename = p.basename(file.path);
    
    String extractedText = '';
    List<String> extractedImagePaths = [];

    try {
      if (extension == '.pdf') {
        final result = await _parsePdf(file);
        extractedText = result.text;
        extractedImagePaths = result.images;
      } else if (extension == '.txt' || extension == '.md') {
        extractedText = await _parseTxt(file);
      } else if (extension == '.docx') {
        final result = await _parseDocx(file);
        extractedText = result.text;
        extractedImagePaths = result.images;
      } else {
        throw FormatException('Unsupported file format: $extension');
      }

      // Generate the OKF Markdown string with YAML frontmatter
      return _buildOKFString(
        title: filename,
        fileType: extension.replaceAll('.', '').toUpperCase(),
        content: extractedText,
        imageRefs: extractedImagePaths,
      );

    } catch (e) {
      throw Exception('Failed to parse document to OKF: $e');
    }
  }

  Future<ParsedResult> _parsePdf(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    
    // In syncfusion_flutter_pdf, extractImages can extract page images
    List<String> imagePaths = [];
    try {
      final tempDir = await getTemporaryDirectory();
      final pdfDir = Directory('${tempDir.path}/${p.basenameWithoutExtension(file.path)}_images');
      if (!await pdfDir.exists()) await pdfDir.create();

      for (int i = 0; i < document.pages.count; i++) {
        // final List<int> imagesBytes = document.pages[i].extractImages().map((img) => img.image).expand((e) => e).toList();
        // We will skip actual saving in this basic implementation to avoid complex byte conversion of PdfImageInfo. 
        // But the capability is here. We will just capture text for now or mock it if needed.
      }
    } catch (_) {}

    document.dispose();
    return ParsedResult(text: text, images: imagePaths);
  }

  Future<String> _parseTxt(File file) async {
    return await file.readAsString();
  }

  Future<ParsedResult> _parseDocx(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    final buffer = StringBuffer();
    List<String> imagePaths = [];
    
    final tempDir = await getTemporaryDirectory();
    final docxDir = Directory('${tempDir.path}/${p.basenameWithoutExtension(file.path)}_images');
    if (!await docxDir.exists()) await docxDir.create();
    
    for (final archiveFile in archive) {
      if (archiveFile.name == 'word/document.xml') {
        final content = utf8.decode(archiveFile.content as List<int>);
        
        // Split by paragraph for decent formatting
        final paragraphs = content.split('<w:p>');
        for (final p in paragraphs) {
          final matches = RegExp(r'<w:t[^>]*>([^<]*)</w:t>').allMatches(p);
          final pText = matches.map((m) => m.group(1)).join('');
          if (pText.trim().isNotEmpty) {
            buffer.writeln(pText);
          }
        }
      } else if (archiveFile.name.startsWith('word/media/') && archiveFile.isFile) {
        final imageFile = File('${docxDir.path}/${p.basename(archiveFile.name)}');
        await imageFile.writeAsBytes(archiveFile.content as List<int>);
        imagePaths.add(imageFile.path);
      }
    }
    
    return ParsedResult(text: buffer.toString(), images: imagePaths);
  }

  /// Constructs the final OKF formatted string
  String _buildOKFString({
    required String title,
    required String fileType,
    required String content,
    required List<String> imageRefs,
  }) {
    final buffer = StringBuffer();
    
    // YAML Frontmatter (OKF standard requirement)
    buffer.writeln('---');
    buffer.writeln('type: document');
    buffer.writeln('title: "$title"');
    buffer.writeln('format: $fileType');
    buffer.writeln('timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('has_images: ${imageRefs.isNotEmpty}');
    buffer.writeln('---');
    buffer.writeln();
    
    // Content body
    buffer.writeln(content);
    
    // Append image references if any
    if (imageRefs.isNotEmpty) {
      buffer.writeln('\n## Extracted Images/Graphs');
      for (var i = 0; i < imageRefs.length; i++) {
        buffer.writeln('![Image ${i+1}](${imageRefs[i]})');
      }
    }
    
    return buffer.toString();
  }
}

class ParsedResult {
  final String text;
  final List<String> images;

  ParsedResult({required this.text, required this.images});
}
