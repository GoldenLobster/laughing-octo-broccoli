import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:http/http.dart' as http;

import '../models/track_result.dart';
import '../models/stream_info.dart';

class InnertubeBridge {
  static final InnertubeBridge instance = InnertubeBridge._internal();
  InnertubeBridge._internal();

  late IsolateQjs _engine;
  final Completer<void> _readyCompleter = Completer<void>();
  bool _isInit = false;

  Future<void> get ready => _readyCompleter.future;

  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;
    _engine = IsolateQjs();

    try {
      // 1. Define __hostFetch in JS global scope
      final setToGlobalObject = await _engine.evaluate("(key, val) => { globalThis[key] = val; }") as JSInvokable;
      
      await setToGlobalObject.invoke([
        "__hostFetch",
        IsolateFunction((String url, String optionsJson) async {
          try {
            final options = jsonDecode(optionsJson);
            final method = options['method'] as String? ?? 'GET';
            final headers = Map<String, String>.from(options['headers'] ?? {});
            final body = options['body'];

            final req = http.Request(method, Uri.parse(url));
            req.headers.addAll(headers);
            if (body != null) {
              req.body = body.toString();
            }

            final streamedResponse = await req.send();
            final response = await http.Response.fromStream(streamedResponse);
            
            final base64Body = base64Encode(response.bodyBytes);

            return jsonEncode({
              'status': response.statusCode,
              'statusText': response.reasonPhrase,
              'headers': response.headers,
              'url': url,
              'bodyBase64': base64Body,
            });
          } catch (e) {
            return jsonEncode({
              'status': 500,
              'statusText': e.toString(),
              'headers': {},
              'url': url,
              'bodyBase64': '',
            });
          }
        }),
      ]);
      setToGlobalObject.free();

      // 2. Load the pre-bundled JS bridge script
      final bundleCode = await rootBundle.loadString('assets/js/bridge.bundle.js');
      await _engine.evaluate(bundleCode);
      
      _readyCompleter.complete();
    } catch (e) {
      _readyCompleter.completeError(e);
      _isInit = false; // allow retry
    }
  }

  Future<List<TrackResult>> search(String query) async {
    await ready;
    // Escape quotes to safely inject string query
    final escapedQuery = query.replaceAll('"', '\\"');
    final script = 'globalThis.ytSearch("$escapedQuery")';
    
    final resultJsonStr = await _engine.evaluate(script) as String;
    final jsonResult = jsonDecode(resultJsonStr);
    
    if (jsonResult is Map && jsonResult.containsKey('error')) {
      throw Exception('JS Error: ${jsonResult['error']}');
    }
    
    final list = jsonResult as List;
    return list.map((e) => TrackResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StreamInfo> resolveStream(String videoId) async {
    await ready;
    final escapedVideoId = videoId.replaceAll('"', '\\"');
    final script = 'globalThis.ytResolveStream("$escapedVideoId")';
    
    final resultJsonStr = await _engine.evaluate(script) as String;
    final jsonResult = jsonDecode(resultJsonStr);
    
    final info = StreamInfo.fromJson(jsonResult as Map<String, dynamic>);
    if (info.error != null) {
      throw Exception('JS Error: ${info.error}');
    }
    return info;
  }

  Future<List<TrackResult>> related(String videoId) async {
    await ready;
    final escapedVideoId = videoId.replaceAll('"', '\\"');
    final script = 'globalThis.ytRelated("$escapedVideoId")';
    
    final resultJsonStr = await _engine.evaluate(script) as String;
    final jsonResult = jsonDecode(resultJsonStr);
    
    if (jsonResult is Map && jsonResult.containsKey('error')) {
      throw Exception('JS Error: ${jsonResult['error']}');
    }
    
    final list = jsonResult as List;
    return list.map((e) => TrackResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}
