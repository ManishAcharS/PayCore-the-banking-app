import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../theme/paycore_theme.dart';

class LoginScreen extends StatefulWidget{const LoginScreen({super.key});@override State<LoginScreen> createState()=>_LoginScreenState();}
class _LoginScreenState extends State<LoginScreen>{
 final email=TextEditingController(),password=TextEditingController();bool loading=false,show=false;
 @override void dispose(){email.dispose();password.dispose();super.dispose();}
 Future<void> submit()async{
  if(email.text.trim().isEmpty||password.text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter your email and password')));return;}
  setState(()=>loading=true);final a=Provider.of<AuthService>(context,listen:false);final r=await a.login(email.text.trim(),password.text);if(!mounted)return;setState(()=>loading=false);
  if(r['token']!=null)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text((r['error']??'Login failed').toString())));
 }
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  const Icon(Icons.account_balance_wallet_rounded,size:50,color:PayCoreTheme.accent),const SizedBox(height:18),const Text('Welcome to PayCore',style:TextStyle(fontSize:32,fontWeight:FontWeight.w800)),const SizedBox(height:8),const Text('A secure banking & payments demo',style:TextStyle(color:Colors.white60)),const SizedBox(height:30),
  GlassCard(child:Column(children:[
   TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined))),
   const SizedBox(height:14),TextField(controller:password,obscureText:!show,decoration:InputDecoration(labelText:'Password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>show=!show),icon:Icon(show?Icons.visibility_off:Icons.visibility)))),
   const SizedBox(height:18),GlassButton(onPressed:loading?null:submit,child:loading?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2)):const Text('Log in')),
   const SizedBox(height:8),TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterScreen())),child:const Text('Create a new account'))
  ])),
  const SizedBox(height:16),const Center(child:Text('SIMULATED FUNDS • EDUCATIONAL DEMO',style:TextStyle(fontSize:11,color:Colors.white38)))
 ])))));
}