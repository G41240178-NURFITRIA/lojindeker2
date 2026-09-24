import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/device_preview_wrapper.dart';
import 'features/auth/screens/landing_screen.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // Inisialisasi Firebase & dotenv
  await FirebaseConfig.initialize();

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
      title: 'D Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          DevicePreviewWrapper(child: child ?? const SizedBox.shrink()),
      home: const LandingScreen(),
    );
  }
}
