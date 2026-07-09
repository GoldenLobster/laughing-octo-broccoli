import 'package:flutter/material.dart';
import 'services/innertube_bridge.dart';
import 'models/track_result.dart';

void main() {
  // Initialize bridge asynchronously in background
  InnertubeBridge.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurora',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Aurora Debug'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _resultText = 'Press the search button to test InnertubeBridge';
  bool _isLoading = false;

  Future<void> _testSearch() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Loading...';
    });
    
    try {
      final results = await InnertubeBridge.instance.search("test song");
      setState(() {
        _resultText = 'Found ${results.length} results.\n\nFirst 3:\n';
        for (var i = 0; i < (results.length > 3 ? 3 : results.length); i++) {
          _resultText += '${results[i].title} - ${results[i].artist}\n';
        }
      });
      print("SEARCH RESULTS:");
      for (var r in results) {
        print(r);
      }
    } catch (e) {
      setState(() {
        _resultText = 'Error: $e';
      });
      print("ERROR: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isLoading) const CircularProgressIndicator()
              else Text(
                _resultText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _testSearch,
        tooltip: 'Search',
        child: const Icon(Icons.search),
      ),
    );
  }
}
