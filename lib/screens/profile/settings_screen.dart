import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoDownloadWifi = true;
  bool _highQualityAR = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configuración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferencias Generales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeThumbColor: AppColors.primaryTeal,
                    title: const Text('Notificaciones MEDUCA',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Recibir avisos sobre nuevos módulos y tareas'),
                    value: _notificationsEnabled,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeThumbColor: AppColors.primaryTeal,
                    title: const Text('Descarga automática en Wi-Fi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle:
                        const Text('Guardar contenido offline sin consumir datos'),
                    value: _autoDownloadWifi,
                    onChanged: (val) => setState(() => _autoDownloadWifi = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeThumbColor: AppColors.primaryTeal,
                    title: const Text('Calidad de modelos AR Alta',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                        'Mejora el detalle de modelos 3D en escaneo'),
                    value: _highQualityAR,
                    onChanged: (val) => setState(() => _highQualityAR = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeThumbColor: AppColors.primaryTeal,
                    title: const Text('Modo Oscuro',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Cambiar tema visual de la aplicación'),
                    value: _darkMode,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Almacenamiento Offline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Almacenamiento utilizado',
                          style: TextStyle(color: AppColors.textMuted)),
                      Text('757 MB / 2.0 GB',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    child: LinearProgressIndicator(
                      value: 0.38,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE2E8F0),
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Limpiar Caché Offline',
                    variant: CustomButtonVariant.outline,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Caché limpiado correctamente.')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Acerca de Panamá Histórica',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: const Column(
                children: [
                  ListTile(
                    title: Text('Versión de la App'),
                    trailing: Text('1.0.0 (Build 104)',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Términos y Condiciones'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Política de Privacidad'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
