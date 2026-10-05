import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../theme/paycore_theme.dart';

class SplashScreen extends StatefulWidget{const SplashScreen({super.key});@override State<SplashScreen> createState()=>_SplashScreenState();}
class _SplashScreenState extends State<SplashScreen>{
 final LocalAuthentication biometric=LocalAuthentication();
 @override void initState(){super.initState();_init();}
 Future<void> _init()async{
  final a=Provider.of<AuthService>(context,listen:false);await a.loadFromPrefs();if(!mounted)return;
  await Future.delayed(const Duration(milliseconds:900));if(!mounted)return;
  if(a.isAuthenticated){try{if(await biometric.isDeviceSupported()&&await biometric.canCheckBiometrics){final ok=await biometric.authenticate(localizedReason:'Unlock PayCore',options:const AuthenticationOptions(biometricOnly:false,useErrorDialogs:true,stickyAuth:true));if(!ok){if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));return;}}}catch(_){}
   if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));
  }else Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const LoginScreen()));
 }
 @override Widget build(BuildContext context)=>Scaffold(body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
  Container(width:92,height:92,decoration:BoxDecoration(color:PayCoreTheme.primary.withOpacity(.16),borderRadius:BorderRadius.circular(28),border:Border.all(color:Colors.white12)),child:const Icon(Icons.account_balance_wallet_rounded,size:48,color:PayCoreTheme.accent)),
  const SizedBox(height:20),const Text('PayCore',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),const SizedBox(height:7),const Text('Banking & Payments Demo',style:TextStyle(color:Colors.white54))
 ])));
}