import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/device_preview_wrapper.dart';
// Path import disesuaikan dengan struktur folder di VS Code
import 'features/patient/screens/consultation_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
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
      home: const ConsultationListScreen(),
    );
  }
}
