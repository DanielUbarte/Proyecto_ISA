import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_logo_leading.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Pantalla independiente de inicio de sesión para el rol DOCENTE.
/// Valida credenciales, comprueba el rol docente y deniega el acceso a estudiantes.
class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _emailController = TextEditingController(text: 'profesor.historica@meduca.gob.pa');
  final _passwordController = TextEditingController(text: '12345678');
  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  Future<void> _handleTeacherLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos requeridos.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInTeacher(
        email: email,
        password: password,
      );

      if (!user.isTeacher) {
        throw Exception('Esta cuenta no cuenta con autorización de docente.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bienvenido, ${user.name}'),
            backgroundColor: AppColors.forestGreen,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.teacherDashboard,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.dangerRed),
                SizedBox(width: 8),
                Text('Acceso Docente', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Text(
              errorMsg,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.topLeft,
                child: AppLogoLeading(),
              ),
              const SizedBox(height: 12),

              // Escudo / Logo con distintivo docente
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.logoGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.logoNavy.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Badge Institucional Docente
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.logoNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, color: AppColors.logoGold, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'PORTAL INSTITUCIONAL DOCENTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Panamá Histórica',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.logoNavy,
                  fontFamily: 'Serif',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gestión curricular, biblioteca de contenidos y seguimiento académico',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),

              const SizedBox(height: 28),

              // Tarjeta del formulario de acceso
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Correo Institucional Docente',
                      hint: 'profesor@meduca.gob.pa',
                      controller: _emailController,
                      prefixIcon: Icons.badge_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      label: 'Contraseña de Acceso',
                      hint: '••••••••',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Ingresar como Docente ➔',
                      isLoading: _isLoading,
                      onPressed: _handleTeacherLogin,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón para volver al acceso de estudiantes
              TextButton.icon(
                icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.logoNavy),
                label: const Text(
                  'Volver al Acceso para Estudiantes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.logoNavy,
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Solo personal docente y académico autorizado por MEDUCA.\nLas credenciales de estudiantes no son válidas en este portal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

