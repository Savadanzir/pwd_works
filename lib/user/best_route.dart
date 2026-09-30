import 'package:flutter/material.dart';

class BestRoute extends StatefulWidget {
  const BestRoute({super.key});
  @override
  State<BestRoute> createState() => _BestRouteState();
}

class _BestRouteState extends State<BestRoute> {
  final _from = TextEditingController();
  final _to = TextEditingController();
  String? _result;

  void _findRoute() {
    if (_from.text.isEmpty || _to.text.isEmpty) return;
    setState(() {
      _result =
          'Best route from ${_from.text} to ${_to.text}:\n\n➡ Via Main Road (12 km)\n'
          '➡ Avoid MG Road - Traffic Block\n'
          '➡ Estimated time: 25 mins\n'
          '➡ Status: Clear ✓';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Best Route')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _from,
              decoration: const InputDecoration(
                  labelText: 'From',
                  prefixIcon: Icon(Icons.trip_origin),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _to,
              decoration: const InputDecoration(
                  labelText: 'To',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.alt_route),
                label: const Text('Find Best Route'),
                onPressed: _findRoute,
              ),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_result!,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}