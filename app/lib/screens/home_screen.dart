import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/paycore_theme.dart';
import 'send_money_screen.dart';
import 'history_screen.dart';
import 'receive_money_screen.dart';
import 'set_pin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  Map<String,dynamic>? data;
  List<dynamic> history = [];
  bool loading = true, hidden = false;

  @override void initState(){super.initState();_load();}

  Future<void> _load() async {
    final a = Provider.of<AuthService>(context,listen:false);
    final api = Provider.of<ApiService>(context,listen:false);
    if(a.token == null){if(mounted)setState(()=>loading=false);return;}
    try {
      final results = await Future.wait([api.getBalance(a.token!),api.getHistory(a.token!)]);
      if(!mounted)return;
      setState(() { data=results[0] as Map<String,dynamic>; history=(results[1] as List).take(5).toList(); loading=false; });
    } catch (_) { if(mounted)setState(()=>loading=false); }
  }

  String money(dynamic value){
    final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
    return 'Rs. ' + n.toStringAsFixed(2);
  }

  @override Widget build(BuildContext context){
    final auth=Provider.of<AuthService>(context);
    final account=data?['account'] as Map<String,dynamic>?;
    final accountNo=(account?['account_number'] ?? '—').toString();
    final name=(auth.user?['name'] ?? 'there').toString();

    return Scaffold(
      body: SafeArea(child:RefreshIndicator(
        onRefresh:_load,
        child:ListView(
          physics:const AlwaysScrollableScrollPhysics(),
          padding:const EdgeInsets.fromLTRB(20,18,20,32),
          children:[
            Row(children:[
              CircleAvatar(backgroundColor:PayCoreTheme.primary.withOpacity(.2),child:Text(name.isEmpty?'P':name[0].toUpperCase())),
              const SizedBox(width:12),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Welcome back',style:TextStyle(color:Colors.white60,fontSize:13)),
                Text(name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700))
              ])),
              IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SetPinScreen())),icon:const Icon(Icons.shield_outlined)),
              IconButton(onPressed:()async{await auth.logout();if(mounted)Navigator.of(context).popUntil((r)=>r.isFirst);},icon:const Icon(Icons.logout_rounded))
            ]),
            const SizedBox(height:20),
            GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                const Expanded(child:Text('AVAILABLE BALANCE',style:TextStyle(color:Colors.white60,fontSize:12,letterSpacing:1.2))),
                IconButton(onPressed:()=>setState(()=>hidden=!hidden),icon:Icon(hidden?Icons.visibility_off_outlined:Icons.visibility_outlined))
              ]),
              Text(hidden?'••••••':money(account?['balance']),style:const TextStyle(fontSize:34,fontWeight:FontWeight.w800)),
              const SizedBox(height:15),Container(height:1,color:Colors.white12),const SizedBox(height:12),
              Row(children:[
                const Icon(Icons.account_balance_outlined,size:18,color:PayCoreTheme.accent),const SizedBox(width:7),
                const Text('Account number',style:TextStyle(color:Colors.white60,fontSize:12)),const Spacer(),
                Flexible(child:Text(accountNo,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700))),
                IconButton(onPressed:accountNo=='—'?null:()async{
                  await Clipboard.setData(ClipboardData(text:accountNo));
                  if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Account number copied')));
                },icon:const Icon(Icons.copy_rounded,size:18))
              ]),
              const Text('SIMULATED FUNDS • DEMO APP',style:TextStyle(fontSize:10,color:PayCoreTheme.accent,fontWeight:FontWeight.w700))
            ])),
            const SizedBox(height:24),
            const Text('Quick actions',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:10),
            Row(children:[
              action(Icons.arrow_upward_rounded,'Send',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SendMoneyScreen()))),
              action(Icons.qr_code_2_rounded,'Receive',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ReceiveMoneyScreen()))),
              action(Icons.qr_code_scanner_rounded,'Scan',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SendMoneyScreen()))),
              action(Icons.receipt_long_rounded,'History',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HistoryScreen())))
            ]),
            const SizedBox(height:25),
            Row(children:[
              const Expanded(child:Text('Recent transactions',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700))),
              TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HistoryScreen())),child:const Text('See all'))
            ]),
            if(loading)const Padding(padding:EdgeInsets.all(25),child:Center(child:CircularProgressIndicator()))
            else if(history.isEmpty)const GlassCard(child:Center(child:Text('No transactions yet',style:TextStyle(color:Colors.white60))))
            else ...history.map((t){
              final n=t['amount'] is num ? (t['amount'] as num).toDouble() : double.tryParse(t['amount'].toString()) ?? 0;
              return Padding(padding:const EdgeInsets.only(bottom:10),child:GlassCard(padding:const EdgeInsets.all(14),child:Row(children:[
                const CircleAvatar(backgroundColor:Colors.white10,child:Icon(Icons.swap_horiz_rounded)),const SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text((t['description'] ?? 'Transfer').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w600)),
                  Text((t['created_at'] ?? '').toString(),style:const TextStyle(fontSize:11,color:Colors.white54))
                ])),
                Text(money(n),style:const TextStyle(fontWeight:FontWeight.w800))
              ])));
            })
          ]
        )
      ))
    );
  }

  Widget action(IconData icon,String label,VoidCallback onTap)=>Expanded(
    child:Padding(padding:const EdgeInsets.only(right:7),child:GlassCard(
      padding:const EdgeInsets.symmetric(vertical:14,horizontal:3),onTap:onTap,
      child:Column(children:[Icon(icon,color:PayCoreTheme.accent),const SizedBox(height:6),Text(label,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600))])
    ))
  );
}