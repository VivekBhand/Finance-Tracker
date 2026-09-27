import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _endpointController;

  @override
  void initState() {
    super.initState();
    final currentEndpoint = ref.read(aiEndpointProvider);
    _endpointController = TextEditingController(text: currentEndpoint);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final box = ref.read(settingsBoxProvider);
    await box.put('aiEndpoint', _endpointController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Currency Selector
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: Colors.white,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEAF9F0),
                child: Text('₹',
                    style: TextStyle(
                        color: Color(0xFF1BAA6A),
                        fontWeight: FontWeight.bold)),
              ),
              title: const Text('App Currency'),
              subtitle: Text(currentCurrency),
              trailing: DropdownButton<String>(
                value: currentCurrency,
                items: const [
                  DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(currencyProvider.notifier).setCurrency(val);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'AI Backend Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No API keys required. The app connects to a free, public Hugging Face Space running Qwen2.5-1.5B.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _endpointController,
              decoration: InputDecoration(
                labelText: 'Hugging Face Space Endpoint',
                hintText: 'https://finance-ai.hf.space',
                prefixIcon: const Icon(Icons.cloud_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BAA6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 24),

            // Help Box for Deploying Own HF Space
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Deploy Your Own Free AI Backend',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Go to huggingface.co/spaces\n'
                    '2. Create a new Space with Docker SDK (CPU Basic - Free)\n'
                    '3. Upload the 3 files inside the backend/ folder of this app\n'
                    '4. Paste your Space URL above',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
