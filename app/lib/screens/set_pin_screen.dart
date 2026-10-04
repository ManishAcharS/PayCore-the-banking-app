import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _pinController = TextEditingController();
  bool _loading = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final token = auth.token;
    if (token != null) {
      final res = await api.pinStatus(token);
      setState(() => _hasPin = res['hasPin'] == true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final api = Provider.of<ApiService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('PIN Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_hasPin ? 'Update PIN (4-6 digits)' : 'Set PIN (4-6 digits)'),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN'),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                final token = auth.token;
                if (token != null) {
                  final res = await api.setPin(token, _pinController.text);
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN set successfully')));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Failed')));
                  }
                }
                setState(() => _loading = false);
              },
              child: _loading ? const CircularProgressIndicator() : const Text('Save PIN'),
            ),
            const Text('PIN is hashed and never stored in plaintext', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
