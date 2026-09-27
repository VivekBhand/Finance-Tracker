import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/holding.dart';
import '../providers/app_providers.dart';
import '../services/document_parser.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final DocumentParser _parser = DocumentParser();
  final TextEditingController _passwordController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  String _statusText = '';
  String? _sanitizedTextPreview;
  List<Holding> _extractedHoldings = [];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.single;
        _extractedHoldings = [];
        _sanitizedTextPreview = null;
      });
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Extracting text & sanitizing PII...';
    });

    try {
      final Uint8List bytes = _selectedFile!.bytes!;
      final String fileName = _selectedFile!.name;
      final String? password = _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim();

      // 1. Extract text and sanitize PII on-device
      final sanitizedText = await _parser.extractFromFile(
        fileName,
        bytes,
        password: password,
      );

      setState(() {
        _sanitizedTextPreview = sanitizedText;
        _statusText = 'AI model parsing holdings...';
      });

      // 2. Send sanitized text to AI Extraction Service
      final aiService = ref.read(aiExtractionServiceProvider);
      final rawHoldings = await aiService.extractHoldings(sanitizedText);

      // 3. Convert JSON to Holding objects
      final holdings = rawHoldings.map((raw) {
        return Holding(
          id: const Uuid().v4(),
          name: raw['name']?.toString() ?? 'Unknown Asset',
          assetType: _parseAssetType(raw['assetType']?.toString()),
          quantity: (raw['quantity'] as num?)?.toDouble() ?? 1.0,
          avgBuyPrice: (raw['avgBuyPrice'] as num?)?.toDouble() ?? 0.0,
          currentPrice: (raw['currentPrice'] as num?)?.toDouble() ??
              (raw['avgBuyPrice'] as num?)?.toDouble() ??
              0.0,
          symbol: raw['symbol']?.toString(),
          isin: raw['isin']?.toString(),
          folioNumber: raw['folioNumber']?.toString(),
          amcName: raw['amcName']?.toString(),
          lastUpdated: DateTime.now(),
        );
      }).toList();

      setState(() {
        _extractedHoldings = holdings;
        _isProcessing = false;
        _statusText = 'Parsed ${holdings.length} holdings!';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error: $e';
      });
    }
  }

  AssetType _parseAssetType(String? value) {
    switch (value?.toLowerCase()) {
      case 'equity':
      case 'stock':
        return AssetType.equity;
      case 'mutualfund':
      case 'mf':
        return AssetType.mutualFund;
      case 'fixeddeposit':
      case 'fd':
        return AssetType.fixedDeposit;
      case 'gold':
        return AssetType.gold;
      case 'ppf':
        return AssetType.ppf;
      case 'bond':
        return AssetType.bond;
      default:
        return AssetType.other;
    }
  }

  Future<void> _saveToPortfolio() async {
    if (_extractedHoldings.isEmpty) return;

    await ref
        .read(holdingsProvider.notifier)
        .upsertHoldings(_extractedHoldings);

    // Refresh AI insights with new holdings
    await ref.read(aiInsightsProvider.notifier).refreshInsights();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Added ${_extractedHoldings.length} holdings to your portfolio!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = _selectedFile != null &&
        _selectedFile!.name.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Account Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // PII Privacy Notice Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1BAA6A).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF1BAA6A)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Privacy Guaranteed: PAN, Aadhaar, Account numbers, and Phone numbers are automatically redacted on-device before processing.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E1E2D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select File Box
            GestureDetector(
              onTap: _isProcessing ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? const Color(0xFF1BAA6A)
                        : Colors.grey.shade300,
                    width: _selectedFile != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.description
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: _selectedFile != null
                          ? const Color(0xFF1BAA6A)
                          : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedFile != null
                          ? _selectedFile!.name
                          : 'Tap to select CAMS/KFintech CAS or Bank Statement (PDF/CSV)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _selectedFile != null
                            ? const Color(0xFF1BAA6A)
                            : Colors.grey.shade800,
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PDF Password Input (if PDF selected)
            if (isPdf) ...[
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'PDF Password (if encrypted)',
                  hintText: 'e.g. DOB DDMMYYYY or PAN',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Process Button
            if (_selectedFile != null)
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processFile,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isProcessing ? 'Processing...' : 'Parse Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BAA6A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

            if (_statusText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // Extracted Holdings Preview
            if (_extractedHoldings.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Extracted Holdings (${_extractedHoldings.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _saveToPortfolio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1BAA6A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save to Portfolio'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._extractedHoldings.map((h) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(h.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${h.assetType.name.toUpperCase()} • ${h.quantity} units @ ₹${h.avgBuyPrice}'),
                      trailing: Text(
                        '₹${(h.quantity * h.avgBuyPrice).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
            ],

            // Sanitized Text Preview Accordion
            if (_sanitizedTextPreview != null) ...[
              const SizedBox(height: 20),
              ExpansionTile(
                title: const Text('View Sanitized Text (PII Redacted)',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _sanitizedTextPreview!,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
