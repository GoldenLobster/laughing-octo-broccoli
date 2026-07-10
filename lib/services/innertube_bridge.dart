import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

import '../models/track_result.dart';
import '../models/stream_info.dart';

class InnertubeBridge {
  static final InnertubeBridge instance = InnertubeBridge._internal();
  InnertubeBridge._internal();

  late JavascriptRuntime _engine;
  final Completer<void> _readyCompleter = Completer<void>();
  bool _isInit = false;

  Future<void> get ready => _readyCompleter.future;

  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;
    _engine = getJavascriptRuntime();

    try {
      // 1. Enable built-in Fetch/Promises
      await _engine.enableFetch();

      // 2. Load the pre-bundled JS bridge script
      final bundleCode = await rootBundle.loadString('assets/js/bridge.bundle.js');
      _engine.evaluate(bundleCode);
      
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
    final script = 'ytSearch("$escapedQuery")';
    
    final jsResult = await _engine.evaluateAsync(script);
    final resultJsonStr = jsResult.stringResult;
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
    final script = 'ytResolveStream("$escapedVideoId")';
    
    final jsResult = await _engine.evaluateAsync(script);
    final resultJsonStr = jsResult.stringResult;
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
    final script = 'ytRelated("$escapedVideoId")';
    
    final jsResult = await _engine.evaluateAsync(script);
    final resultJsonStr = jsResult.stringResult;
    final jsonResult = jsonDecode(resultJsonStr);
    
    if (jsonResult is Map && jsonResult.containsKey('error')) {
      throw Exception('JS Error: ${jsonResult['error']}');
    }
    
    final list = jsonResult as List;
    return list.map((e) => TrackResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}
