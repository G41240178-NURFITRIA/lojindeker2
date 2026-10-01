import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/device_preview_wrapper.dart';
import 'core/services/notification_service.dart';
import 'core/services/session_service.dart';

import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // Inisialisasi Firebase & dotenv
  await FirebaseConfig.initialize();

  // Inisialisasi SessionService untuk auto-timeout
  await SessionService.instance.init();

  // Set system UI overlay style to match status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const DCareApp());
}

class DCareApp extends StatelessWidget {
  const DCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SessionService.navigatorKey,
      title: 'D Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final content = DevicePreviewWrapper(
          child: child ?? const SizedBox.shrink(),
        );
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => SessionService.instance.onUserInteraction(),
          onPointerMove: (_) => SessionService.instance.onUserInteraction(),
          child: content,
        );
      },
      home: const AuthGate(),
    );
  }
}
