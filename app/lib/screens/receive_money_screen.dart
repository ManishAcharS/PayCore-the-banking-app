import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/paycore_theme.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});
  @override State<ReceiveMoneyScreen> createState()=>_ReceiveMoneyScreenState();
}
class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen>{
  String qrData=''; String accountNo=''; String name=''; bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    final auth=Provider.of<AuthService>(context,listen:false),api=Provider.of<ApiService>(context,listen:false);
    if(auth.token==null)return;
    try{
      final bal=await api.getBalance(auth.token!);
      final acc=bal['account'] as Map<String,dynamic>;
      final no=(acc['account_number']??'').toString();
      final n=(auth.user?['name']??'User').toString();
      final res=await api.generateQR(auth.token!,no,n);
      if(!mounted)return;
      setState(()=>{qrData=(res['qrData']??'').toString(),accountNo=no,name=n,loading=false});
    }catch(_){if(mounted)setState(()=>loading=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Receive money')),
    body:loading?const Center(child:CircularProgressIndicator()):ListView(
      padding:const EdgeInsets.all(20),children:[
        const Text('Let someone pay you',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
        const SizedBox(height:8),const Text('Share your PayCore QR or account number.',style:TextStyle(color:Colors.white60)),
        const SizedBox(height:22),
        GlassCard(child:Column(children:[
          Text(name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)),
          const SizedBox(height:4),const Text('PayCore account',style:TextStyle(color:Colors.white54)),
          const SizedBox(height:18),
          if(qrData.isNotEmpty)Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:QrImageView(data:qrData,version:QrVersions.auto,size:230)),
          const SizedBox(height:18),
          const Text('ACCOUNT NUMBER',style:TextStyle(color:Colors.white54,fontSize:11,letterSpacing:1.1)),
          const SizedBox(height:5),Text(accountNo,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,letterSpacing:1.4)),
          TextButton.icon(onPressed:()async{await Clipboard.setData(ClipboardData(text:accountNo));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Account number copied')));},icon:const Icon(Icons.copy_rounded),label:const Text('Copy account number'))
        ])),
        const SizedBox(height:18),const Center(child:Text('Scan this QR to pay me',style:TextStyle(color:Colors.white60)))
      ]
    )
  );
}