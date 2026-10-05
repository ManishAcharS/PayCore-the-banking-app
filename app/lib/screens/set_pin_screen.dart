import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/paycore_theme.dart';

class SetPinScreen extends StatefulWidget{const SetPinScreen({super.key});@override State<SetPinScreen> createState()=>_SetPinScreenState();}
class _SetPinScreenState extends State<SetPinScreen>{
 final pin=TextEditingController();bool loading=false,hasPin=false;
 @override void initState(){super.initState();_check();}
 @override void dispose(){pin.dispose();super.dispose();}
 Future<void> _check()async{final a=Provider.of<AuthService>(context,listen:false),api=Provider.of<ApiService>(context,listen:false);if(a.token==null)return;final r=await api.pinStatus(a.token!);if(mounted)setState(()=>hasPin=r['hasPin']==true);}
 Future<void> save()async{
  if(pin.text.length<4||pin.text.length>6||int.tryParse(pin.text)==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('PIN must contain 4 to 6 digits')));return;}
  final a=Provider.of<AuthService>(context,listen:false),api=Provider.of<ApiService>(context,listen:false);if(a.token==null)return;setState(()=>loading=true);final r=await api.setPin(a.token!,pin.text);if(!mounted)return;setState(()=>loading=false);
  if(r['success']==true){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('PIN saved securely')));Navigator.pop(context);}else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text((r['error']??'Could not save PIN').toString())));
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(hasPin?'Update PIN':'Set PIN')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Icon(Icons.lock_person_rounded,size:55,color:PayCoreTheme.accent),const SizedBox(height:14),
  Text(hasPin?'Update your payment PIN':'Protect your payments',style:const TextStyle(fontSize:28,fontWeight:FontWeight.w800)),
  const SizedBox(height:8),const Text('Your PIN is hashed by the backend and is never stored in plaintext.',style:TextStyle(color:Colors.white60)),
  const SizedBox(height:22),GlassCard(child:Column(children:[
   TextField(controller:pin,obscureText:true,maxLength:6,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'4–6 digit PIN',prefixIcon:Icon(Icons.pin_outlined))),
   const SizedBox(height:12),GlassButton(onPressed:loading?null:save,child:loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)):Text(hasPin?'Update PIN':'Save PIN'))
  ]))
 ]));
}