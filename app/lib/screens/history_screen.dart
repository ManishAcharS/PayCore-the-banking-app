import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/paycore_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState()=>_HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen>{
  List<dynamic> history=[]; bool loading=true; String? error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final a=Provider.of<AuthService>(context,listen:false),api=Provider.of<ApiService>(context,listen:false);
    if(a.token==null){setState(()=>loading=false);return;}
    try{final h=await api.getHistory(a.token!);if(mounted)setState(()=>{history=h,loading=false,error=null});}
    catch(_){if(mounted)setState(()=>{loading=false,error='Could not load transaction history'});}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Transaction history')),
    body:RefreshIndicator(onRefresh:_load,child:loading?const Center(child:CircularProgressIndicator()):error!=null?ListView(children:[Padding(padding:const EdgeInsets.all(40),child:Center(child:Text(error!,textAlign:TextAlign.center))) ]):history.isEmpty?ListView(children:[Padding(padding:const EdgeInsets.all(50),child:Center(child:Text('No transactions yet',style:TextStyle(color:Colors.white60))))]):ListView.builder(
      padding:const EdgeInsets.all(16),itemCount:history.length,itemBuilder:(context,i){
        final t=history[i];final n=t['amount'] is num?(t['amount'] as num).toDouble():double.tryParse(t['amount'].toString())??0;
        return Padding(padding:const EdgeInsets.only(bottom:10),child:GlassCard(child:Row(children:[
          const CircleAvatar(backgroundColor:Colors.white10,child:Icon(Icons.receipt_long_rounded)),const SizedBox(width:14),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((t['description']??'Transfer').toString(),style:const TextStyle(fontWeight:FontWeight.w700)),
            const SizedBox(height:5),Text((t['created_at']??'').toString(),style:const TextStyle(fontSize:11,color:Colors.white54))
          ])),
          Text('Rs. '+n.toStringAsFixed(2),style:const TextStyle(fontWeight:FontWeight.w800))
        ])));
      }
    )
  );
}