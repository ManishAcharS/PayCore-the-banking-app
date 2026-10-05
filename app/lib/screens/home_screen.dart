import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'send_money_screen.dart';
import 'history_screen.dart';
import 'receive_money_screen.dart';
import 'set_pin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? balanceData;
  List<dynamic> history = [];

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
      final hist = await api.getHistory(token);
      setState(() {
        balanceData = bal;
        history = hist.take(5).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayCore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPinScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Balance', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${(balanceData?['account']?['balance'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text('Account: ${balanceData?['account']?['account_number'] ?? '—'}'),
                    const Text('SIMULATED FUNDS - NOT REAL MONEY', style: TextStyle(fontSize: 10, color: Colors.red)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyScreen())),
                    child: const Text('Send Money'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    child: const Text('History'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveMoneyScreen())),
                child: const Text('Receive Money (QR)'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...history.map((t) => ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(t['description'] ?? 'Transfer'),
                  subtitle: Text('Rs. '),
                )),
          ],
        ),
      ),
    );
  }
}
