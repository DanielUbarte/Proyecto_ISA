import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class PanamaHistoricaApp extends StatelessWidget {
  const PanamaHistoricaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panamá Histórica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
