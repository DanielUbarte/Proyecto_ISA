import 'package:flutter/material.dart';
import '../app/routes.dart';
import '../app/theme.dart';

/// Botón flotante con diseño y símbolo de Inteligencia Artificial
/// que permite acceder al Historiador IA desde cualquier pantalla de la app.
class HistorianFloatingButton extends StatelessWidget {
  final String heroTag;

  const HistorianFloatingButton({
    super.key,
    this.heroTag = 'historian_ai_fab',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.logoGold.withValues(alpha: 0.85),
          width: 1.6,
        ),
        gradient: const LinearGradient(
          colors: [
            AppColors.logoNavy,
            AppColors.logoNavyLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoNavy.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.logoGold.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        tooltip: 'Consultar al Historiador IA',
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.historian);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 26,
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.amberBadge,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'IA',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
