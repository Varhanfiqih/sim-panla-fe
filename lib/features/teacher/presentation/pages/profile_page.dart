import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/user.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _bg = Color(0xFFF3F2F9);
  static const Color _card = Color(0xFFEEF0FA);
  static const Color _text = Color(0xFF1C2435);
  static const Color _muted = Color(0xFF98A0B5);
  static const Color _primary = Color(0xFF325EEA);
  static const Color _danger = Color(0xFFE7706D);
  final AuthRepository _authRepository = AuthRepository();
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  Future<void> _refreshProfile() async {
    try {
      final user = await _authRepository.getProfile();
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthUserUpdated(user));
    } catch (_) {
      // Keep showing the cached profile if refresh fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is! AuthAuthenticated) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent(context, state.user);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(context, user),
          const SizedBox(height: 24),
          _buildActivePeriodCard(),
          const SizedBox(height: 22),
          Text(
            'ACCOUNT SETTINGS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _muted,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingTile(
            context: context,
            icon: Icons.person,
            title: 'Personal Info',
            subtitle: 'NIP ${user.nip}',
            onTap: () => _showPersonalInfoSheet(context, user),
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            context: context,
            icon: Icons.lock,
            title: 'Security/Change Password',
            subtitle: 'Manage your security settings',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            context: context,
            icon: Icons.help,
            title: 'Help Center',
            subtitle: 'FAQ and support system',
          ),
          const SizedBox(height: 10),
          _buildSettingTile(
            context: context,
            icon: Icons.info,
            title: 'About App',
            subtitle: 'SIM-PANLA v2.0.1 Pasuruan',
          ),
          const SizedBox(height: 26),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final roleLabel = user.isGuruBK ? 'GURU BK' : 'GURU MATA PELAJARAN';
    final photoUrl = _resolvePhotoUrl(user.profilePhotoUrl);

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: _uploadingPhoto
                    ? null
                    : () => _showPhotoActions(context, user),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF5C8F8A),
                    border: Border.all(
                      color: const Color(0xFFE8EAF5),
                      width: 3,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _uploadingPhoto
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarInitial(user),
                        )
                      : _avatarInitial(user),
                ),
              ),
              Positioned(
                right: -2,
                bottom: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 33,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'NIP ${user.nip}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE7FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: _primary),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(User user) {
    return Center(
      child: Text(
        user.shortName.substring(0, 1).toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 34,
        ),
      ),
    );
  }

  String? _resolvePhotoUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final photoUri = Uri.tryParse(value);
    final baseUri = Uri.parse(ApiConstants.baseUrl);
    if (photoUri == null) return null;

    if (photoUri.hasScheme) {
      return photoUri
          .replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          )
          .toString();
    }

    return baseUri.resolve(value).toString();
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final user = await _authRepository.updateProfilePhoto(picked.path);
      if (!mounted) return;
      if (!context.mounted) return;
      authBloc.add(AuthUserUpdated(user));
      _showMessage('Foto profil berhasil diperbarui.');
    } catch (error) {
      if (!mounted) return;
      if (!context.mounted) return;
      _showMessage(_errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _showPhotoActions(BuildContext context, User user) async {
    final photoUrl = _resolvePhotoUrl(user.profilePhotoUrl);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.visibility_rounded),
                  title: const Text('Lihat foto profil'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPhotoPreview(context, photoUrl);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(
                  photoUrl == null ? 'Pilih foto profil' : 'Ganti foto profil',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadPhoto(context);
                },
              ),
              if (photoUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: _danger,
                  ),
                  title: const Text(
                    'Hapus foto profil',
                    style: TextStyle(color: _danger),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeletePhoto(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoPreview(
    BuildContext context,
    String photoUrl,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text(
                      'Foto gagal dimuat',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton.filled(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePhoto(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Foto Profil'),
        content: const Text(
          'Foto profil akan dihapus dan avatar kembali menggunakan inisial nama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final user = await _authRepository.deleteProfilePhoto();
      if (!mounted) return;
      if (!context.mounted) return;
      authBloc.add(AuthUserUpdated(user));
      _showMessage('Foto profil berhasil dihapus.');
    } catch (error) {
      if (!mounted) return;
      if (!context.mounted) return;
      _showMessage(_errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var saving = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirmation = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          InputDecoration decoration(
            String label,
            bool obscure,
            VoidCallback toggle,
          ) {
            return InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              suffixIcon: IconButton(
                tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
                onPressed: toggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Ganti Password'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: decoration(
                        'Password lama',
                        obscureCurrent,
                        () => setDialogState(
                          () => obscureCurrent = !obscureCurrent,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Password lama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscureNew,
                      decoration: decoration(
                        'Password baru',
                        obscureNew,
                        () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Minimal 8 karakter';
                        }
                        if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                            !RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Gunakan kombinasi huruf dan angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmationController,
                      obscureText: obscureConfirmation,
                      decoration: decoration(
                        'Konfirmasi password baru',
                        obscureConfirmation,
                        () => setDialogState(
                          () => obscureConfirmation = !obscureConfirmation,
                        ),
                      ),
                      validator: (value) => value != passwordController.text
                          ? 'Konfirmasi password tidak cocok'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          final message = await _authRepository.changePassword(
                            currentPassword: currentController.text,
                            newPassword: passwordController.text,
                            confirmation: confirmationController.text,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          _showMessage(message);
                        } catch (error) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() => saving = false);
                          _showMessage(_errorMessage(error), isError: true);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException && error.error is ApiException) {
      return (error.error as ApiException).message;
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? _danger : const Color(0xFF249B66),
        ),
      );
  }

  Widget _buildActivePeriodCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERIODE AKTIF',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tahun Ajaran 2024/2025 Genap',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _primary),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur ini akan segera tersedia')),
            ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC3C9DA)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoSheet(BuildContext context, User user) {
    final subjects = user.subjects;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3D9E8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Informasi Personal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nama', user.name),
                  _buildInfoRow('NIP', user.nip),
                  _buildInfoRow('Peran', user.role),
                  _buildInfoRow(
                    'Wali Kelas',
                    (user.waliKelas == null || user.waliKelas!.isEmpty)
                        ? '-'
                        : user.waliKelas!,
                  ),
                  _buildInfoRow(
                    'Status Inval/Piket',
                    user.isInvalPiket ? 'Aktif' : 'Tidak Aktif',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Mata Pelajaran Diampu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (subjects.isEmpty)
                    Text(
                      '- Tidak ada data mapel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: _muted,
                      ),
                    )
                  else
                    ...subjects.map(
                      (subject) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(
                                Icons.circle,
                                size: 7,
                                color: _primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                subject,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: _text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: _text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          'Keluar',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFFAD8D3),
          foregroundColor: _danger,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
