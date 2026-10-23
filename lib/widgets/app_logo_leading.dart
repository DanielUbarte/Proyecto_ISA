import 'package:flutter/material.dart';
import '../app/routes.dart';
import '../app/theme.dart';

/// Logotipo institucional ubicado en la esquina superior izquierda de cada pantalla.
/// Al tocarlo, redirige siempre de forma inmediata a la pantalla de Inicio (Home).
class AppLogoLeading extends StatelessWidget {
  final double size;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppLogoLeading({
    super.key,
    this.size = 36.0,
    this.showBackButton = false,
    this.onBack,
  });

  void _navigateToHome(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == AppRoutes.home) {
      // Si ya se encuentra en Inicio, no reinicia la pila innecesariamente
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoButton = Tooltip(
      message: 'Ir a Inicio (Panamá Histórica)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToHome(context),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.logoGold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.logoNavy.withValues(alpha: 0.16),
                    blurRadius: 5,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!showBackButton) {
      return Center(child: logoButton);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 4),
        logoButton,
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.logoNavy,
          ),
          tooltip: 'Volver',
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
      ],
    );
  }
}
