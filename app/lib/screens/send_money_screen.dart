import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _scanQR() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Scan QR')),
          body: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                try {
                  final data = barcodes.first.rawValue;
                  if (data != null) {
                    final parsed = Map<String, dynamic>.from(Uri.splitQueryString(data));
                    if (parsed['accountNumber'] == null && data.startsWith('{')) {
                      // try json
                    }
                  }
                } catch (e) {}
              }
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _authenticate() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (canCheck) {
        return await auth.authenticate(
          localizedReason: 'Confirm payment with biometric',
          options: const AuthenticationOptions(biometricOnly: false),
        );
      }
    } catch (e) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final api = Provider.of<ApiService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _accountController, decoration: const InputDecoration(labelText: 'Recipient Account Number')),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _scanQR, child: const Text('Scan QR'))),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : () async {
                final ok = await _authenticate();
                if (!ok) {
                  // allow PIN fallback flow - for now just warn
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication required')));
                  return;
                }
                setState(() => _loading = true);
                final token = authService.token;
                if (token != null) {
                  final res = await api.transfer(
                    token,
                    _accountController.text,
                    double.tryParse(_amountController.text) ?? 0,
                    _descController.text,
                  );
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer successful (demo)')));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Failed')));
                  }
                }
                setState(() => _loading = false);
              },
              child: _loading ? const CircularProgressIndicator() : const Text('Confirm Transfer'),
            ),
            const Text('Fingerprint/biometric lock required before confirming payment', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
