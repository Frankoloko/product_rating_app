import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({Key? key}) : super(key: key);

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture barcodeCapture) {
    if (_isScanned) return; // prevent double scans
    final barcode = barcodeCapture.barcodes.first.rawValue ?? '';

    if (barcode.isNotEmpty) {
      setState(() => _isScanned = true);
      Navigator.pop(context, barcode); // return barcode to previous page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
