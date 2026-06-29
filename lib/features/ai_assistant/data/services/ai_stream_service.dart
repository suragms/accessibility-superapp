import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../domain/services/safety_layer.dart';

/// Client service executing chunked streaming requests to the server-side LLM proxy.
class AiStreamService {
  final Dio _dio = Dio();

  /// Resolves the user request and yields a stream of text chunks from the proxy server.
  Stream<String> sendMessageStream(String prompt, String systemPrompt) async* {
    // 1. Run safety checks on the input prompt
    final inputSafety = SafetyLayer.checkPrompt(prompt);
    if (!inputSafety.isSafe) {
      yield inputSafety.alertMessage ?? 'Safety policy violation.';
      return;
    }
    if (inputSafety.isEmergency) {
      yield inputSafety.alertMessage ?? 'Emergency detected.';
      return;
    }

    final proxyUrl = dotenv.env['PROXY_URL'] ?? 'http://localhost:3000';
    final endpoint = '$proxyUrl/api/chat';

    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        endpoint,
        data: {
          'prompt': prompt,
          'systemPrompt': systemPrompt,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/plain',
          },
        ),
      );
    } catch (e) {
      String errorMsg = 'Failed to connect to AI Assistant. ';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg += 'Please verify the proxy server is running at $proxyUrl and you are connected to the network.';
        } else if (e.response != null) {
          errorMsg += 'Server returned status: ${e.response?.statusCode}';
        } else {
          errorMsg += e.message ?? '';
        }
      } else {
        errorMsg += e.toString();
      }
      throw Exception(errorMsg);
    }

    if (response.data == null) {
      throw Exception('Empty response stream received from proxy server.');
    }

    final accumulator = StringBuffer();

    // Read response body stream chunk-by-chunk
    await for (final Uint8List chunk in response.data!.stream) {
      final textChunk = utf8.decode(chunk);
      accumulator.write(textChunk);

      // 2. Run safety checks on the accumulated streamed output
      final outputSafety = SafetyLayer.checkPrompt(accumulator.toString());
      if (!outputSafety.isSafe) {
        yield '\n[Safety Alert: ${outputSafety.alertMessage ?? "Safety violation detected"}]';
        return;
      }

      yield textChunk;
    }
  }
}
