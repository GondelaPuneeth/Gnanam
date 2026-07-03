import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../core/errors/llm_exceptions.dart';

/// Manages downloading of GGUF model files and LoRA adapters.
/// 
/// Includes progress tracking, resume support, and SHA-256 validation.
class ModelDownloader {
  final Dio _dio;
  
  ModelDownloader({Dio? dio}) : _dio = dio ?? Dio();

  /// Downloads a model file with resume support and validates its checksum.
  /// 
  /// [url] - The direct download URL
  /// [filename] - The target filename (e.g. 'gemma-2-2b-it.gguf')
  /// [expectedSha256] - Optional checksum for validation
  /// [onProgress] - Callback for UI progress updates (0.0 to 1.0)
  Future<File> downloadModel({
    required String url,
    required String filename,
    String? expectedSha256,
    void Function(double progress)? onProgress,
    Map<String, String>? headers,
  }) async {
    final savePath = await _getModelPath(filename);
    final file = File(savePath);
    
    // Check if fully downloaded and valid
    if (await file.exists()) {
      if (expectedSha256 != null) {
        final isValid = await _verifyChecksum(file, expectedSha256);
        if (isValid) {
          onProgress?.call(1.0);
          return file;
        }
        // If invalid, delete and re-download
        await file.delete();
      }
      // If no checksum, proceed to download section which handles resume via Range headers
    }

    try {
      int downloadedBytes = 0;
      
      // Check for partial download to resume
      if (await file.exists()) {
        downloadedBytes = await file.length();
      }
      
      // Resolve redirect before downloading to prevent AWS S3 401 errors
      String finalUrl = url;
      if (headers != null && headers.isNotEmpty) {
        try {
          final redirectOptions = Options(
            headers: headers,
            followRedirects: false,
            validateStatus: (status) => status != null && status < 400,
          );
          final response = await _dio.get(url, options: redirectOptions);
          if (response.statusCode == 301 || response.statusCode == 302 || response.statusCode == 307 || response.statusCode == 308) {
            finalUrl = response.headers.value('location') ?? url;
          }
        } catch (e) {
          throw ModelDownloadException(
            'Failed to authenticate or resolve model URL. Check your Hugging Face Token.',
            url: url,
            cause: e,
          );
        }
      }
      
      final requestHeaders = <String, dynamic>{};
      // Note: We deliberately do not forward the provided auth `headers` to `finalUrl` 
      // because AWS S3 presigned URLs reject requests containing an Authorization header.
      if (downloadedBytes > 0) {
        requestHeaders['Range'] = 'bytes=$downloadedBytes-';
      }

      final options = Options(
        responseType: ResponseType.stream,
        headers: requestHeaders,
      );

      final response = await _dio.get<ResponseBody>(finalUrl, options: options);
      
      // Handle range requests gracefully if server doesn't support them
      final isPartial = response.statusCode == 206;
      if (!isPartial && downloadedBytes > 0) {
        downloadedBytes = 0; // Restart from scratch
      }

      final totalBytes = int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '-1'
      ) ?? -1;
      
      final totalExpected = totalBytes > 0 ? totalBytes + downloadedBytes : -1;

      final sink = file.openWrite(mode: isPartial ? FileMode.append : FileMode.write);
      
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        if (totalExpected > 0) {
          onProgress?.call(downloadedBytes / totalExpected);
        }
      }
      
      await sink.close();

      // Validate checksum if provided
      if (expectedSha256 != null) {
        final isValid = await _verifyChecksum(file, expectedSha256);
        if (!isValid) {
          await file.delete();
          throw ChecksumMismatchException(
            'Downloaded model failed checksum validation',
            expectedHash: expectedSha256,
            url: url,
          );
        }
      }

      return file;
    } on DioException catch (e) {
      throw ModelDownloadException(
        'Failed to download model: ${e.message}',
        url: url,
        httpStatusCode: e.response?.statusCode,
        cause: e,
      );
    } catch (e) {
      throw ModelDownloadException(
        'Unexpected error downloading model: $e',
        url: url,
        cause: e,
      );
    }
  }

  /// Calculates SHA-256 of the file and compares to expected hash.
  Future<bool> _verifyChecksum(File file, String expectedSha256) async {
    try {
      final stream = file.openRead();
      final hash = await sha256.bind(stream).first;
      return hash.toString().toLowerCase() == expectedSha256.toLowerCase();
    } catch (e) {
      return false;
    }
  }

  /// Gets the absolute path for storing a model file.
  Future<String> _getModelPath(String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    
    return '${modelsDir.path}/$filename';
  }
}
