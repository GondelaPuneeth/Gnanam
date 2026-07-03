import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

/// Represents the analyzed output of an image.
class VisionAnalysisResult {
  final String extractedText;
  final String? visualDescription; // Used if a secondary Vision-Language Model is active
  final List<String> detectedObjects;
  final List<String> imageLabels;

  VisionAnalysisResult({
    required this.extractedText,
    this.visualDescription,
    this.detectedObjects = const [],
    this.imageLabels = const [],
  });

  /// Formats the result as a prompt injection for the LLM.
  String toPromptContext() {
    final buffer = StringBuffer();
    buffer.writeln('--- Image Analysis ---');
    if (visualDescription != null) {
      buffer.writeln('Visual Description: $visualDescription');
    }
    if (imageLabels.isNotEmpty) {
      buffer.writeln('Image Labels (Confidence): ${imageLabels.join(", ")}');
    }
    if (detectedObjects.isNotEmpty) {
      buffer.writeln('Detected Objects: ${detectedObjects.join(", ")}');
    }
    if (extractedText.isNotEmpty) {
      buffer.writeln('Extracted Text (OCR):\n$extractedText');
    }
    buffer.writeln('----------------------');
    return buffer.toString();
  }
}

/// Controller for Advanced Camera Sensing.
/// 
/// Combines Google ML Kit (for robust text/math OCR) and optionally
/// a secondary local Vision Model (like Moondream or PaliGemma) for understanding 
/// graphs and diagrams.
class VisionSensingController {
  final TextRecognizer _textRecognizer;
  final ImageLabeler _imageLabeler;
  final ObjectDetector _objectDetector;

  VisionSensingController() 
      : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin),
        _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.7)),
        _objectDetector = ObjectDetector(options: ObjectDetectorOptions(classifyObjects: true, mode: DetectionMode.single, multipleObjects: false));

  /// Analyzes an image and returns a comprehensive structured result.
  Future<VisionAnalysisResult> analyzeImage(File imageFile) async {
    // 1. Run high-speed OCR using ML Kit
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    // 2. Image Labeling (Identifies general concepts in the image)
    final labels = await _imageLabeler.processImage(inputImage);
    final labelStrings = labels.map((l) => '${l.label} (${(l.confidence * 100).toStringAsFixed(1)}%)').toList();

    // 3. Object Detection (Localizes and classifies specific objects)
    final objects = await _objectDetector.processImage(inputImage);
    final objectStrings = objects.expand((obj) => obj.labels.map((l) => l.text)).toSet().toList();
    
    // Since llm_llamacpp currently does not fully support multimodal input without extra bindings,
    // we use ML Kit's advanced sensing (labels & objects) to give the LLM robust context of the scene.
    const String? description = null;

    return VisionAnalysisResult(
      extractedText: recognizedText.text,
      visualDescription: description,
      imageLabels: labelStrings,
      detectedObjects: objectStrings,
    );
  }

  /// Closes resources
  void dispose() {
    _textRecognizer.close();
    _imageLabeler.close();
    _objectDetector.close();
  }
}
