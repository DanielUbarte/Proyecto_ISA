import 'package:flutter/material.dart';
import '../../app/app.dart';
import '../../app/theme.dart';
import '../../widgets/app_logo_leading.dart';
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
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = PanamaHistoricaApp.themeNotifier.value == ThemeMode.dark;
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkMode = value;
    });
    PanamaHistoricaApp.themeNotifier.value =
        value ? ThemeMode.dark : ThemeMode.light;
  }

  void _showTermsAndConditions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.logoGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description, color: AppColors.logoGold, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Términos y Condiciones',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                        ),
                        Text('Panamá Histórica • Proyecto MEDUCA', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Propósito Académico y Pedagógico'),
                      _buildSectionBody(
                          'La aplicación Panamá Histórica es una plataforma educativa oficial diseñada para el fortalecimiento de la identidad nacional, el estudio cívico y la memoria histórica de los estudiantes y docentes de la República de Panamá.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('2. Fuentes Documentales y Propiedad Intelectual'),
                      _buildSectionBody(
                          'Todo el contenido, textos, fotografías históricas y libros disponibles en la aplicación (incluyendo la obra oficial "El 9 de enero de 1964: lo que no me contaron" de Wendy Tribaldos) son materiales con fines estrictamente educativos y de investigación, protegidos bajo la legislación de derecho de autor y patrimonio nacional.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('3. Uso del Historiador Inteligente (IA)'),
                      _buildSectionBody(
                          'El Historiador IA opera bajo un protocolo de Recuperación Aumentada por Generación (RAG) estricto. Sus respuestas están circunscritas exclusivamente a las fuentes documentales incorporadas dentro de la plataforma. Está prohibido utilizar el asistente para fines ajenos a la indagación histórica y educativa.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('4. Responsabilidad del Usuario'),
                      _buildSectionBody(
                          'El estudiante se compromete a hacer un uso respetuoso y constructivo de los recursos, preservando la veracidad de los hechos históricos y respetando los símbolos de la patria panameña.'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.logoNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido y Aceptar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.logoNavy.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.logoNavy, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Política de Privacidad',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                        ),
                        Text('Protección Integral de Datos Estudiantiles', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Protección de la Privacidad del Menor'),
                      _buildSectionBody(
                          'Panamá Histórica cumple estrictamente con las regulaciones de protección de datos personales de menores de edad. Los datos de perfil (nombre, grado y centro escolar) se conservan de forma segura y confidencial.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('2. Cero Rastreadores y Publicidad'),
                      _buildSectionBody(
                          'Esta aplicación no contiene anuncios, rastreadores comerciales ni telemetría con fines publicitarios. La información académica y de progreso se utiliza únicamente para respaldar la experiencia de aprendizaje del estudiante.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('3. Seguridad en el Procesamiento de IA'),
                      _buildSectionBody(
                          'Las preguntas formuladas al Historiador IA se procesan con salvaguardas de privacidad y no se utilizan para entrenar modelos externos ni se comparten con terceros no autorizados.'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('4. Almacenamiento Local y Seguro'),
                      _buildSectionBody(
                          'Los materiales descargados para el modo sin conexión residen exclusivamente en el almacenamiento seguro de tu dispositivo móvil.'),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.logoNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.logoNavy,
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: const AppLogoLeading(showBackButton: true),
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

            Material(
              color: Theme.of(context).cardTheme.color ?? AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppColors.logoGold,
                      activeTrackColor: AppColors.logoNavy,
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
                      activeThumbColor: AppColors.logoGold,
                      activeTrackColor: AppColors.logoNavy,
                      title: const Text('Descarga automática en Wi-Fi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Guardar contenido offline sin consumir datos'),
                      value: _autoDownloadWifi,
                      onChanged: (val) => setState(() => _autoDownloadWifi = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: AppColors.logoGold,
                      activeTrackColor: AppColors.logoNavy,
                      title: const Text('Calidad de modelos AR Alta',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Mejora el detalle de modelos 3D en escaneo'),
                      value: _highQualityAR,
                      onChanged: (val) => setState(() => _highQualityAR = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: AppColors.logoGold,
                      activeTrackColor: AppColors.logoNavy,
                      title: const Text('Modo Oscuro',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Cambiar tema visual de la aplicación'),
                      value: _darkMode,
                      onChanged: _toggleDarkMode,
                    ),
                  ],
                ),
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
                color: Theme.of(context).cardTheme.color ?? AppColors.surfaceWhite,
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
                      color: AppColors.logoNavy,
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

            Material(
              color: Theme.of(context).cardTheme.color ?? AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Column(
                  children: [
                    const ListTile(
                      title: Text('Versión de la App'),
                      trailing: Text('1.0.0 (Build 104)',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Términos y Condiciones'),
                      subtitle: const Text('Lineamientos de uso educativo y académico', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showTermsAndConditions(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Política de Privacidad'),
                      subtitle: const Text('Tratamiento y protección de datos', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
