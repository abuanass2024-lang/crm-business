import 'package:flutter/material.dart';
import 'app_theme.dart';

/// التطبيق الرئيسي — يستخدم AppTheme (Light + Dark)
class CrmApp extends StatelessWidget {
  const CrmApp({
    super.key,
    required this.home,
  });

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM Business',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: home,
    );
  }
}
