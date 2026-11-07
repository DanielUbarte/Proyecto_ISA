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
import '../screens/splash/splash_screen.dart';
import '../modules/contemporanea/contemporanea_screen.dart';
import '../modules/contemporanea/contemporanea_content.dart';
import '../screens/teacher/teacher_login_screen.dart';
import '../screens/teacher/teacher_dashboard_screen.dart';
import '../screens/teacher/teacher_documents_screen.dart';
import '../screens/teacher/teacher_add_document_screen.dart';
import '../screens/teacher/teacher_students_screen.dart';
import '../screens/teacher/teacher_evaluations_screen.dart';
import '../screens/teacher/evaluation_register_screen.dart';
import '../models/academic_evaluation_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String modules = '/modules';
  static const String moduleDetail = '/module_detail';
  static const String content = '/content';
  static const String historian = '/historian';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String contemporanea = '/contemporanea';
  static const String contemporaneaContent = '/contemporanea/content';

  // Rutas exclusivas del Rol Docente
  static const String teacherLogin = '/teacher/login';
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherDocuments = '/teacher/documents';
  static const String teacherAddDocument = '/teacher/add_document';
  static const String teacherStudents = '/teacher/students';
  static const String teacherEvaluations = '/teacher/evaluations';
  static const String teacherRegisterEvaluation = '/teacher/evaluations/register';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
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
      contemporanea: (context) => const ContemporaneaScreen(),
      contemporaneaContent: (context) => const ContemporaneaContent(),

      // Vistas Docente
      teacherLogin: (context) => const TeacherLoginScreen(),
      teacherDashboard: (context) => const TeacherDashboardScreen(),
      teacherDocuments: (context) => const TeacherDocumentsScreen(),
      teacherAddDocument: (context) => const TeacherAddDocumentScreen(),
      teacherStudents: (context) => const TeacherStudentsScreen(),
      teacherEvaluations: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          return TeacherEvaluationsScreen(initialStudentId: args);
        } else if (args is Map<String, dynamic>) {
          return TeacherEvaluationsScreen(
            initialStudentId: args['studentId'] as String?,
            initialTab: args['initialTab'] as int? ?? 0,
          );
        }
        return const TeacherEvaluationsScreen();
      },
      teacherRegisterEvaluation: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is AcademicEvaluationModel) {
          return EvaluationRegisterScreen(evaluationToEdit: args);
        } else if (args is String) {
          return EvaluationRegisterScreen(initialStudentId: args);
        }
        return const EvaluationRegisterScreen();
      },
    };
  }
}
