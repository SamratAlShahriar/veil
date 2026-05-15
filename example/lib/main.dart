import 'package:flutter/material.dart';
import 'package:veil/veil.dart';

/// Entry point for the veil example app.
void main() => runApp(const ExampleApp());

/// Root application widget for the veil example.
class ExampleApp extends StatelessWidget {
  /// Creates an [ExampleApp].
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

/// Interactive demo page for the veil package.
class ExamplePage extends StatefulWidget {
  /// Creates an [ExamplePage].
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  bool _enable = true;
  double _greyOpacity = 1.0;
  double _blurSigma = 0.0;
  double _overlayOpacity = 0.35;
  Color _overlayColor = Colors.black;

  UnveiledBlurMode _priceBadgeBlurMode = UnveiledBlurMode.none;
  UnveiledBlurMode _buttonBlurMode = UnveiledBlurMode.none;

  static const Map<String, Color> _overlayColors = {
    'Black': Colors.black,
    'Amber': Colors.orange,
    'Blue': Color(0xFF1A237E),
    'Red': Colors.red,
  };

  static const Map<String, UnveiledBlurMode> _blurModes = {
    'None': UnveiledBlurMode.none,
    'Inherit': UnveiledBlurMode.inherit,
    'Custom (1.5)': UnveiledBlurMode.custom(sigma: 1.5),
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
              blurSigma: _blurSigma,
              overlayOpacity: _overlayOpacity,
              overlayColor: _overlayColor,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          const Text(
                            'Was \$299',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          // Unveiled — blur mode controlled by UI
                          Unveiled(
                            blurMode: _priceBadgeBlurMode,
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
                      // Unveiled — blur mode controlled by UI
                      Unveiled(
                        blurMode: _buttonBlurMode,
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

            // ── Veil controls ──────────────────────────────────────────────
            const Text(
              'Veil controls',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable veil'),
              value: _enable,
              onChanged: (v) => setState(() => _enable = v),
            ),
            ListTile(
              title:
                  Text('Grey opacity: ${_greyOpacity.toStringAsFixed(2)}'),
              subtitle: Slider(
                value: _greyOpacity,
                onChanged: (v) => setState(() => _greyOpacity = v),
              ),
            ),
            ListTile(
              title: Text('Blur sigma: ${_blurSigma.toStringAsFixed(1)}'),
              subtitle: Slider(
                value: _blurSigma,
                max: 20.0,
                onChanged: (v) => setState(() => _blurSigma = v),
              ),
            ),
            ListTile(
              title: Text(
                  'Overlay opacity: ${_overlayOpacity.toStringAsFixed(2)}'),
              subtitle: Slider(
                value: _overlayOpacity,
                onChanged: (v) => setState(() => _overlayOpacity = v),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                    labelStyle:
                        TextStyle(color: selected ? Colors.white : null),
                    onSelected: (_) =>
                        setState(() => _overlayColor = entry.value),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Unveiled blur mode controls ─────────────────────────────
            const Text(
              'Unveiled blur mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Controls blur on each Unveiled child independently.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Price badge:'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: _blurModes.entries.map((entry) {
                  final selected = _priceBadgeBlurMode == entry.value;
                  return ChoiceChip(
                    label: Text(entry.key),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _priceBadgeBlurMode = entry.value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Add to Cart button:'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: _blurModes.entries.map((entry) {
                  final selected = _buttonBlurMode == entry.value;
                  return ChoiceChip(
                    label: Text(entry.key),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _buttonBlurMode = entry.value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
