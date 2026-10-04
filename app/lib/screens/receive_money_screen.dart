import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  String qrData = '';
  Map<String, dynamic>? accountData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final token = auth.token;
    if (token != null) {
      final bal = await api.getBalance(token);
      final acc = bal['account'];
      final res = await api.generateQR(token, acc['account_number'], auth.user?['name'] ?? 'User');
      setState(() {
        qrData = res['qrData'] ?? '{"accountNumber":"","name":""}';
        accountData = acc;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Money')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (qrData.isNotEmpty)
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
              ),
            const SizedBox(height: 16),
            Text('Account: '),
            const Text('Share this QR to receive money'),
          ],
        ),
      ),
    );
  }
}
