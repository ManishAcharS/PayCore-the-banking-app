import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import '../theme/paycore_theme.dart';

class RegisterScreen extends StatefulWidget{const RegisterScreen({super.key});@override State<RegisterScreen> createState()=>_RegisterScreenState();}
class _RegisterScreenState extends State<RegisterScreen>{
 final name=TextEditingController(),email=TextEditingController(),password=TextEditingController();bool loading=false,show=false;
 @override void dispose(){name.dispose();email.dispose();password.dispose();super.dispose();}
 Future<void> submit()async{
  if(name.text.trim().isEmpty||email.text.trim().isEmpty||password.text.length<6){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter your name, email and a password of at least 6 characters')));return;}
  setState(()=>loading=true);final a=Provider.of<AuthService>(context,listen:false);final r=await a.register(name.text.trim(),email.text.trim(),password.text);if(!mounted)return;setState(()=>loading=false);
  if(r['token']!=null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Account created with simulated demo funds')));Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));}else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text((r['error']??'Registration failed').toString())));
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Create account')),body:SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('Start with PayCore',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('Create a demo account and explore secure payments.',style:TextStyle(color:Colors.white60)),const SizedBox(height:24),
 GlassCard(child:Column(children:[
  TextField(controller:name,decoration:const InputDecoration(labelText:'Full name',prefixIcon:Icon(Icons.person_outline))),const SizedBox(height:12),
  TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:12),
  TextField(controller:password,obscureText:!show,decoration:InputDecoration(labelText:'Password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>show=!show),icon:Icon(show?Icons.visibility_off:Icons.visibility)))),
  const SizedBox(height:18),GlassButton(onPressed:loading?null:submit,child:loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)):const Text('Create account'))
 ])),const SizedBox(height:18),const Center(child:Text('SIMULATED FUNDS • NOT REAL MONEY',style:TextStyle(fontSize:11,color:Colors.white38)))
])));
}