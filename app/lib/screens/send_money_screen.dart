import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
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

  @override
  State<PayCoreScanner> createState() => _PayCoreScannerState();
}

class _PayCoreScannerState extends State<PayCoreScanner>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;

  bool handled = false;
  bool checkingPermission = true;
  bool starting = false;
  bool recovering = false;
  bool _cameraFlowRunning = false;
  String? userMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCameraPermissionAndStart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || handled) return;

    if (state == AppLifecycleState.resumed) {
      // The permission dialog itself can trigger a resumed lifecycle event.
      // Never start a second permission/camera flow while one is active.
      if (!_cameraFlowRunning) {
        _ensureCameraPermissionAndStart();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopScanner();
    }
  }

  Future<void> _ensureCameraPermissionAndStart() async {
    if (!mounted || handled || recovering || _cameraFlowRunning) return;

    _cameraFlowRunning = true;

    setState(() {
      checkingPermission = true;
      userMessage = null;
    });

    try {
      var status = await Permission.camera.status;

      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (!mounted || handled) return;

      if (!status.isGranted) {
        setState(() {
          checkingPermission = false;
          starting = false;
          userMessage = status.isPermanentlyDenied
              ? 'Camera permission is blocked. Enable Camera permission '
                  'for PayCore in Android Settings, then tap Retry.'
              : 'Camera permission is required to scan a PayCore QR code.';
        });
        return;
      }

      checkingPermission = false;
      await _initializeScanner();
    } catch (error, stackTrace) {
      debugPrint('PayCore camera permission check failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          checkingPermission = false;
          starting = false;
          recovering = false;
          userMessage =
              'Camera permission could not be checked. Tap Retry to try again.';
        });
      }
    } finally {
      _cameraFlowRunning = false;
    }
  }

  Future<void> _initializeScanner() async {
    if (!mounted || handled) return;

    final existing = _controller;
    if (existing != null) {
      if (existing.value.isRunning) {
        setState(() => starting = false);
        return;
      }

      try {
        await existing.start();
        if (mounted && !handled) {
          setState(() {
            starting = false;
            userMessage = null;
          });
        }
        return;
      } catch (error, stackTrace) {
        debugPrint('PayCore QR scanner restart failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        await _disposeController();
      }
    }

    final controller = MobileScannerController(
      autoStart: false,
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );

    _controller = controller;

    if (mounted) {
      setState(() {
        starting = true;
        userMessage = null;
      });
    }

    try {
      await controller.start();

      if (!mounted || handled) return;

      setState(() {
        starting = false;
        recovering = false;
        userMessage = null;
      });
    } on MobileScannerException catch (error, stackTrace) {
      debugPrint(
        'PayCore QR scanner start failed: '
        '${error.errorCode.name}: '
        '${error.errorDetails?.message ?? 'no details'}',
      );
      debugPrintStack(stackTrace: stackTrace);
      await _disposeController();

      if (mounted) {
        setState(() {
          starting = false;
          recovering = false;
          userMessage =
              'The camera could not be started. Tap Retry to try again.';
        });
      }
    } catch (error, stackTrace) {
      debugPrint('PayCore QR scanner start failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _disposeController();

      if (mounted) {
        setState(() {
          starting = false;
          recovering = false;
          userMessage =
              'The camera could not be started. Tap Retry to try again.';
        });
      }
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;

    if (controller == null) return;

    try {
      await controller.stop();
    } catch (error, stackTrace) {
      debugPrint('PayCore QR scanner stop failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    controller.dispose();
  }

  Future<void> _stopScanner() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRunning) return;

    try {
      await controller.stop();
    } catch (error, stackTrace) {
      debugPrint('PayCore QR scanner pause failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _retryScanner() async {
    if (!mounted || handled || _cameraFlowRunning) return;

    // Retry is a complete camera reset. Do not reuse the old controller,
    // because it may contain a failed/stale CameraX session from the
    // permission handoff.
    await _disposeController();

    if (!mounted || handled) return;

    setState(() {
      checkingPermission = true;
      starting = false;
      recovering = false;
      userMessage = null;
    });

    await _ensureCameraPermissionAndStart();
  }

  void detect(BarcodeCapture capture) {
    if (handled) return;

    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere(
          (value) => value.trim().isNotEmpty,
          orElse: () => '',
        );

    if (raw.isEmpty) return;

    try {
      Map<String, dynamic> parsed;

      if (raw.trim().startsWith('{')) {
        parsed = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        parsed = Uri.splitQueryString(raw).map(
          (key, value) => MapEntry(key, value),
        );
      }

      final accountNumber =
          (parsed['accountNumber'] ?? parsed['account_number'] ?? '')
              .toString()
              .trim();

      if (accountNumber.isEmpty) {
        throw const FormatException(
          'This QR code is not a valid PayCore payment QR.',
        );
      }

      handled = true;
      final controller = _controller;
      if (controller != null) {
        controller.stop();
      }

      Navigator.pop(
        context,
        {
          'accountNumber': accountNumber,
          'name': (parsed['name'] ?? '').toString(),
        },
      );
    } catch (error, stackTrace) {
      debugPrint('PayCore QR parsing failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        userMessage =
            'This QR code is not a valid PayCore payment QR. '
            'Please scan the QR generated by PayCore.';
      });
    }
  }

  Widget _cameraError(
    BuildContext context,
    MobileScannerException exception,
  ) {
    debugPrint(
      'PayCore QR scanner error: '
      '${exception.errorCode.name}'
      '${exception.errorDetails?.message == null ? '' : ': '
          '${exception.errorDetails?.message}'}',
    );

    final busy = checkingPermission || starting || _cameraFlowRunning;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 58),
              const SizedBox(height: 18),
              Text(
                busy ? 'Starting camera…' : 'Camera unavailable',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                busy
                    ? 'PayCore is checking camera access and starting the scanner.'
                    : userMessage ??
                        'The camera could not be started. Tap Retry to try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: busy ? null : _retryScanner,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(busy ? 'Starting camera…' : 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final busy = checkingPermission || starting;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan & Pay'),
        actions: [
          if (controller != null)
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, _) {
                final enabled = state.isRunning &&
                    state.torchState != TorchState.unavailable;

                return IconButton(
                  onPressed: enabled ? controller.toggleTorch : null,
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                  ),
                  tooltip: 'Toggle flashlight',
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          if (controller != null)
            MobileScanner(
              controller: controller,
              onDetect: detect,
              errorBuilder: _cameraError,
              placeholderBuilder: (context) => const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: busy
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.no_photography_outlined,
                              size: 58,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Camera permission needed',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              userMessage ??
                                  'Allow Camera permission for PayCore '
                                      'to scan a QR code.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white60,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),
                            OutlinedButton.icon(
                              onPressed: _retryScanner,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                            if (userMessage?.contains(
                                  'Android Settings',
                                ) ??
                                false)
                              TextButton(
                                onPressed: openAppSettings,
                                child: const Text('Open Settings'),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                border: Border.all(
                  color: PayCoreTheme.accent,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Positioned(
            bottom: 34,
            left: 20,
            right: 20,
            child: GlassCard(
              child: Text(
                busy
                    ? 'Preparing camera…'
                    : userMessage ??
                        'Point your camera at a PayCore QR code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
