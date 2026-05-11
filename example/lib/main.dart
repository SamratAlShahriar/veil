import 'package:flutter/material.dart';
import 'package:veil/veil.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'veil example',
      theme: ThemeData.light(useMaterial3: true),
      home: const ExamplePage(),
    );
  }
}



class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  bool _enable = true;
  double _greyOpacity = 1.0;
  double _overlayOpacity = 0.35;
  Color _overlayColor = Colors.black;

  static const Map<String, Color> _overlayColors = {
    'Black': Colors.black,
    'Amber': Colors.orange,
    'Blue': Color(0xFF1A237E),
    'Red': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('veil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Demo card ──────────────────────────────────────────────────
            Veil(
              enable: _enable,
              greyOpacity: _greyOpacity,
              overlayOpacity: _overlayOpacity,
              overlayColor: _overlayColor,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coloured banner — veiled
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.orange],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.headphones,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Premium Wireless Headphones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Crystal-clear audio with 40-hour battery life.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Veiled — greyscale + dimmed
                          const Text(
                            'Was \$299',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          // Unveiled — full colour, not dimmed
                          Unveiled(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '\$199 — In Stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Unveiled button — full colour, not dimmed
                      Unveiled(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {},
                            child: const Text('Add to Cart'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Controls ───────────────────────────────────────────────────
            SwitchListTile(
              title: const Text('Enable veil'),
              value: _enable,
              onChanged: (v) => setState(() => _enable = v),
            ),
            ListTile(
              title: Text(
                'Grey opacity: ${_greyOpacity.toStringAsFixed(2)}',
              ),
              subtitle: Slider(
                value: _greyOpacity,
                onChanged: (v) => setState(() => _greyOpacity = v),
              ),
            ),
            ListTile(
              title: Text(
                'Overlay opacity: ${_overlayOpacity.toStringAsFixed(2)}',
              ),
              subtitle: Slider(
                value: _overlayOpacity,
                onChanged: (v) => setState(() => _overlayOpacity = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Overlay colour:'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: _overlayColors.entries.map((entry) {
                  final selected = _overlayColor == entry.value;
                  return ChoiceChip(
                    label: Text(entry.key),
                    selected: selected,
                    selectedColor: entry.value,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                    ),
                    onSelected: (_) =>
                        setState(() => _overlayColor = entry.value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
