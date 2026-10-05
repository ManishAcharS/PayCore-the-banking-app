import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/paycore_theme.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});
  @override State<SendMoneyScreen> createState()=>_SendMoneyScreenState();
}
class _SendMoneyScreenState extends State<SendMoneyScreen>{
  final account=TextEditingController(),amount=TextEditingController(),desc=TextEditingController();
  bool loading=false;
  @override void dispose(){account.dispose();amount.dispose();desc.dispose();super.dispose();}

  Future<void> scan() async {
    final result=await Navigator.push<Map<String,String>>(context,MaterialPageRoute(builder:(_)=>const PayCoreScanner()));
    if(result!=null&&mounted){account.text=result['accountNumber']??'';ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Recipient: '+(result['name']??'PayCore user'))));setState((){});}
  }

  Future<bool> authenticate() async {
    final auth=LocalAuthentication();
    try{
      if(await auth.isDeviceSupported() && await auth.canCheckBiometrics){
        return await auth.authenticate(localizedReason:'Confirm this PayCore demo payment',options:const AuthenticationOptions(biometricOnly:false,useErrorDialogs:true,stickyAuth:true));
      }
    }catch(_){}
    return false;
  }

  Future<bool> pinFallback() async {
    final pin=TextEditingController();
    final value=await showDialog<String>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Confirm with PIN'),content:TextField(controller:pin,obscureText:true,maxLength:6,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'PayCore PIN')),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,pin.text),child:const Text('Verify'))]
    ));
    pin.dispose();
    if(value==null||value.isEmpty)return false;
    final a=Provider.of<AuthService>(context,listen:false),api=Provider.of<ApiService>(context,listen:false);
    if(a.token==null)return false;
    final res=await api.verifyPin(a.token!,value);
    return res['success']==true;
  }

  Future<void> transfer() async {
    final a=Provider.of<AuthService>(context,listen:false),api=Provider.of<ApiService>(context,listen:false);
    final to=account.text.trim(), value=double.tryParse(amount.text.trim());
    if(to.isEmpty||value==null||value<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a valid recipient and amount')));return;}
    final confirmed=await showModalBottomSheet<bool>(context:context,backgroundColor:Colors.transparent,builder:(_)=>Container(
      padding:const EdgeInsets.all(24),decoration:const BoxDecoration(color:PayCoreTheme.surface,borderRadius:BorderRadius.vertical(top:Radius.circular(28))),
      child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Confirm payment',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:18),
        Text('To  '+to,style:const TextStyle(color:Colors.white60)),const SizedBox(height:6),Text('Rs. '+value.toStringAsFixed(2),style:const TextStyle(fontSize:30,fontWeight:FontWeight.w800)),const SizedBox(height:8),
        Text(desc.text.trim().isEmpty?'Transfer':'Note: '+desc.text.trim(),style:const TextStyle(color:Colors.white60)),const SizedBox(height:14),
        const Text('SIMULATED FUNDS • DEMO APP',style:TextStyle(color:PayCoreTheme.accent,fontSize:11,fontWeight:FontWeight.w700)),const SizedBox(height:18),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Continue')))
      ])
    ));
    if(confirmed!=true)return;
    var ok=await authenticate();
    if(!ok)ok=await pinFallback();
    if(!ok){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Biometric or valid PIN is required')));return;}
    if(a.token==null)return;
    setState(()=>loading=true);
    try{
      final res=await api.transfer(a.token!,to,value,desc.text.trim());
      if(!mounted)return;
      if(res['success']==true){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Payment successful • demo funds transferred')));Navigator.pop(context,true);}
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text((res['error']??'Transfer failed').toString())));
    }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not complete the transfer')));}
    if(mounted)setState(()=>loading=false);
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Send money')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      const Text('Send securely',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Use an account number or scan a PayCore QR.',style:TextStyle(color:Colors.white60)),const SizedBox(height:22),
      GlassCard(child:Column(children:[
        TextField(controller:account,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Recipient account number',prefixIcon:Icon(Icons.account_balance_outlined))),
        const SizedBox(height:12),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount',prefixIcon:Icon(Icons.currency_rupee_rounded))),
        const SizedBox(height:12),TextField(controller:desc,maxLines:2,decoration:const InputDecoration(labelText:'Description (optional)',prefixIcon:Icon(Icons.notes_rounded))),
        const SizedBox(height:16),SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:loading?null:scan,icon:const Icon(Icons.qr_code_scanner_rounded),label:const Text('Scan QR'))),
        const SizedBox(height:12),SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:loading?null:transfer,child:loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)):const Text('Confirm transfer')))
      ]))
    ])
  );
}

class PayCoreScanner extends StatefulWidget {
  const PayCoreScanner({super.key});
  @override State<PayCoreScanner> createState()=>_PayCoreScannerState();
}

class _PayCoreScannerState extends State<PayCoreScanner> with WidgetsBindingObserver{
  final controller=MobileScannerController(autoStart:false);
  bool handled=false,torch=false;
  String? error;

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_)=>_startScanner());
  }

  Future<void> _startScanner() async {
    if(!mounted||handled)return;
    setState(()=>error=null);
    try{
      await controller.start();
    }on MobileScannerException catch(e){
      if(!mounted)return;
      final message=e.errorCode==MobileScannerErrorCode.permissionDenied
          ?'Camera permission was denied. Allow camera access for PayCore in Android settings, then tap Retry.'
          :'Camera could not be started ('+e.errorCode.name+'). Please check that the device camera is available, then tap Retry.';
      setState(()=>error=message);
    }catch(_){
      if(mounted)setState(()=>error='Camera could not be started. Please check camera access and try again.');
    }
  }

  @override
  void dispose(){
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(!mounted||handled)return;
    switch(state){
      case AppLifecycleState.resumed: _startScanner(); break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden: controller.stop(); break;
      case AppLifecycleState.detached: break;
    }
  }

  void detect(BarcodeCapture capture){
    if(handled)return;
    final raw=capture.barcodes.map((b)=>b.rawValue).whereType<String>().firstWhere((s)=>s.trim().isNotEmpty,orElse:()=> '');
    if(raw.isEmpty)return;
    try{
      Map<String,dynamic> parsed;
      if(raw.trim().startsWith('{')) parsed=jsonDecode(raw) as Map<String,dynamic>;
      else parsed=Uri.splitQueryString(raw).map((k,v)=>MapEntry(k,v));
      final no=(parsed['accountNumber']??parsed['account_number']??'').toString().trim();
      if(no.isEmpty)throw const FormatException('This QR does not contain a PayCore account number.');
      handled=true;controller.stop();
      Navigator.pop(context,{'accountNumber':no,'name':(parsed['name']??'').toString()});
    }catch(e){
      setState(()=>error='Invalid PayCore QR: '+e.toString());
      controller.stop();
    }
  }

  Widget _scannerError(BuildContext context,MobileScannerException exception,Widget? child){
    final message=exception.errorCode==MobileScannerErrorCode.permissionDenied
        ?'Camera permission is required to scan PayCore QR codes.'
        :'Camera error: '+exception.errorCode.name+'.';
    return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      const Icon(Icons.no_photography_outlined,size:56),
      const SizedBox(height:16),
      Text(message,textAlign:TextAlign.center,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),
      const SizedBox(height:10),
      const Text('Grant camera access, then tap Retry.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white60)),
      const SizedBox(height:18),
      OutlinedButton.icon(onPressed:_startScanner,icon:const Icon(Icons.refresh),label:const Text('Retry')),
    ])));
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    backgroundColor:Colors.black,
    appBar:AppBar(title:const Text('Scan & Pay'),actions:[
      IconButton(onPressed:()=>controller.toggleTorch(),icon:Icon(torch?Icons.flash_on:Icons.flash_off)),
    ]),
    body:Stack(children:[
      MobileScanner(controller:controller,onDetect:detect,errorBuilder:_scannerError,placeholderBuilder:(context,child)=>const Center(child:CircularProgressIndicator())),
      Center(child:Container(width:270,height:270,decoration:BoxDecoration(border:Border.all(color:PayCoreTheme.accent,width:3),borderRadius:BorderRadius.circular(28)))),
      Positioned(bottom:34,left:20,right:20,child:GlassCard(child:Column(children:[
        Text(error??'Point your camera at a PayCore QR code',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w600)),
        if(error!=null)Padding(padding:const EdgeInsets.only(top:10),child:OutlinedButton.icon(onPressed:_startScanner,icon:const Icon(Icons.refresh),label:const Text('Retry'))),
      ]))),
    ]),
  );
}
