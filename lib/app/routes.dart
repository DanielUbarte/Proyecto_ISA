import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/modules/modules_screen.dart';
import '../screens/modules/module_detail_screen.dart';
import '../screens/modules/content_screen.dart';
import '../screens/historian/historian_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String modules = '/modules';
  static const String moduleDetail = '/module_detail';
  static const String content = '/content';
  static const String historian = '/historian';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) => const HomeScreen(),
      modules: (context) => const ModulesScreen(),
      moduleDetail: (context) => const ModuleDetailScreen(),
      content: (context) => const ContentScreen(),
      historian: (context) => const HistorianScreen(),
      progress: (context) => const ProgressScreen(),
      profile: (context) => const ProfileScreen(),
      settings: (context) => const SettingsScreen(),
    };
  }
}
