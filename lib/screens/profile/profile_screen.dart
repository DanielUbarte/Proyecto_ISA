import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/download_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TTSService _ttsService = TTSService();
  final DownloadService _downloadService = DownloadService();

  late UserModel _user;
  bool _ttsEnabled = true;
  final String _selectedLanguage = 'Español panameño';
  final String _textSize = 'A+';
  bool _isContemporaneaDownloaded = false;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser ?? UserModel.mock();
    _ttsEnabled = _ttsService.isTTSEnabled;
    _checkDownloads();
  }

  Future<void> _checkDownloads() async {
    final downloaded = await _downloadService.isModuleDownloaded('mod_contemporanea');
    if (mounted) {
      setState(() {
        _isContemporaneaDownloaded = downloaded;
      });
    }
  }

  Future<void> _deleteDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar descargas'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar los archivos descargados de "Panamá Contemporánea"? Deberás descargarlos nuevamente para acceder sin conexión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadService.removeModuleDownload('mod_contemporanea');
      await _checkDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivos descargados de Panamá Contemporánea eliminados.'),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _saveChanges() {
    _ttsService.toggleTTS(_ttsEnabled);
    _ttsService.setVoice(_selectedLanguage);
    _ttsService.setTextSize(_textSize);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambios guardados correctamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Text('Panamá Histórica'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primaryTeal,
                        backgroundImage: _user.avatarUrl.isNotEmpty
                            ? (_user.avatarUrl.startsWith('assets/')
                                ? AssetImage(_user.avatarUrl) as ImageProvider
                                : NetworkImage(_user.avatarUrl) as ImageProvider)
                            : null,
                        child: _user.avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white, size: 46)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontFamily: 'Serif',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sandAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🎓 ${_user.grade} - ${_user.institution}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Device and Level Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smartphone,
                        color: AppColors.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dispositivo en uso',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          _user.deviceInUse,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Nivel de Usuario',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      Text(
                        _user.levelTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Módulos Descargados Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.download_for_offline,
                        color: AppColors.primaryTeal),
                    SizedBox(width: 8),
                    Text(
                      'Archivos Descargados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  _isContemporaneaDownloaded ? '36 MB ocupados' : '0 MB ocupados',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isContemporaneaDownloaded)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.sandAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history_edu,
                          color: Color(0xFF7C2D12), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panamá Contemporánea',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '36 MB • 4 materiales descargados',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.dangerRed, size: 24),
                      tooltip: 'Eliminar descarga',
                      onPressed: _deleteDownload,
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textMuted),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No tienes ningún material descargado sin conexión.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Save and Logout Buttons
            CustomButton(
              text: '💾 Guardar cambios',
              variant: CustomButtonVariant.green,
              onPressed: _saveChanges,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: '🚪 Cerrar sesión',
              variant: CustomButtonVariant.danger,
              onPressed: _handleLogout,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }
}
