import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/journal_bloc.dart';

class JournalFormPage extends StatefulWidget {
  const JournalFormPage({super.key});

  @override
  State<JournalFormPage> createState() => _JournalFormPageState();
}

class _JournalFormPageState extends State<JournalFormPage> {
  static const int _maxImageBytes = 1024 * 1024;

  final _materiController = TextEditingController();
  final _imagePicker = ImagePicker();

  final _cleanlinessOptions = const [
    'Sangat Bersih',
    'Bersih',
    'Cukup',
    'Kurang',
  ];

  @override
  void dispose() {
    _materiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      await _setCompressedImage(File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      await _setCompressedImage(File(pickedFile.path));
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowMultiple: false,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'csv',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'zip',
          'rar',
        ],
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilihan file dibatalkan')),
        );
        return;
      }

      final picked = result.files.single;
      String? path = picked.path;

      if (path == null && picked.bytes != null) {
        final safeName = (picked.name.isEmpty ? 'lampiran.bin' : picked.name)
            .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final tempFile = File('${Directory.systemTemp.path}/$safeName');
        await tempFile.writeAsBytes(picked.bytes!, flush: true);
        if (!mounted) return;
        path = tempFile.path;
      }

      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File tidak didukung. Coba pilih dari penyimpanan lokal.',
            ),
          ),
        );
        return;
      }

      final selectedFile = File(path);
      if (_isImagePath(path)) {
        await _setCompressedImage(selectedFile);
      } else {
        context.read<JournalBloc>().add(SetAttachment(selectedFile));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File terpilih: ${picked.name}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
    }
  }

  Future<void> _setCompressedImage(File source) async {
    try {
      final compressed = await _compressImageToLimit(source);
      final sizeKb = (await compressed.length() / 1024).ceil();
      if (!mounted) return;

      context.read<JournalBloc>().add(SetAttachment(compressed));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gambar siap diunggah ($sizeKb KB)')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<File> _compressImageToLimit(File source) async {
    if (!await source.exists()) {
      throw Exception('File gambar tidak ditemukan.');
    }

    if (await source.length() <= _maxImageBytes) {
      return source;
    }

    var quality = 85;
    var width = 1600;
    var height = 1600;
    File? result;

    for (var attempt = 0; attempt < 7; attempt++) {
      final targetPath =
          '${Directory.systemTemp.path}/journal_${DateTime.now().microsecondsSinceEpoch}_$attempt.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        targetPath,
        quality: quality,
        minWidth: width,
        minHeight: height,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed == null) {
        throw Exception('Gambar gagal dikompresi.');
      }

      result = File(compressed.path);
      if (await result.length() <= _maxImageBytes) {
        return result;
      }

      quality = (quality - 12).clamp(25, 85).toInt();
      width = (width * 0.82).round().clamp(720, 1600).toInt();
      height = (height * 0.82).round().clamp(720, 1600).toInt();
    }

    if (result != null && await result.length() <= _maxImageBytes) {
      return result;
    }

    throw Exception(
      'Ukuran gambar masih lebih dari 1 MB. Pilih gambar dengan resolusi lebih kecil.',
    );
  }

  bool _isImagePath(String path) {
    final extension = path.split('.').last.toLowerCase();
    return const ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );

          Navigator.of(context).popUntil(
            (route) => route.isFirst || route.settings.name == '/schedule',
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else if (state is JournalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFB91C1C),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is JournalSubmitting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is! JournalStudentsLoaded) {
          return const Scaffold(body: Center(child: Text('State tidak valid')));
        }

        if (_materiController.text != state.material) {
          _materiController.text = state.material;
          _materiController.selection = TextSelection.fromPosition(
            TextPosition(offset: _materiController.text.length),
          );
        }

        final isValid = state.material.trim().isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF121826)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Form Jurnal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF121826),
                fontSize: 20,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildHeroCard(state),
              const SizedBox(height: 14),
              _buildMaterialCard(state),
              const SizedBox(height: 14),
              _buildAttendanceCard(state),
              const SizedBox(height: 14),
              _buildCleanlinessCard(state),
              const SizedBox(height: 14),
              _buildAttachmentCard(state),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isValid
                      ? () => context.read<JournalBloc>().add(SubmitJournal())
                      : null,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    'Simpan Jurnal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2250E8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F5),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(JournalStudentsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2250E8), Color(0xFF3B6AF8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SETUP JURNAL',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Laporan KBM Harian',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaPill(Icons.groups_2_rounded, state.className),
              _metaPill(Icons.menu_book_rounded, state.subjectName),
              _metaPill(Icons.schedule_rounded, state.timeSlot),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(JournalStudentsLoaded state) {
    return _sectionCard(
      title: 'Materi Pembelajaran',
      child: TextField(
        controller: _materiController,
        maxLines: 5,
        onChanged: (value) {
          context.read<JournalBloc>().add(UpdateMaterial(value));
        },
        decoration: InputDecoration(
          hintText:
              'Tuliskan topik, tujuan pembelajaran, dan metode yang digunakan hari ini...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 13,
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8ECF7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8ECF7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2250E8), width: 1.4),
          ),
        ),
        style: GoogleFonts.inter(
          color: const Color(0xFF1F2937),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(JournalStudentsLoaded state) {
    return _sectionCard(
      title: 'Rekap Kehadiran',
      child: Row(
        children: [
          Expanded(
            child: _attendanceItem(
              label: 'Hadir',
              count: state.hadirCount,
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _attendanceItem(
              label: 'Sakit',
              count: state.sakitCount,
              color: const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _attendanceItem(
              label: 'Izin',
              count: state.izinCount,
              color: const Color(0xFFCA8A04),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _attendanceItem(
              label: 'Alpa',
              count: state.alpaCount,
              color: const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceItem({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanlinessCard(JournalStudentsLoaded state) {
    return _sectionCard(
      title: 'Kebersihan Kelas',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _cleanlinessOptions.map((option) {
          final selected = state.cleanliness == option;
          return ChoiceChip(
            selected: selected,
            label: Text(
              option,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF2250E8)
                    : const Color(0xFF64748B),
              ),
            ),
            backgroundColor: const Color(0xFFF3F5FF),
            selectedColor: const Color(0xFFE8EEFF),
            side: BorderSide(
              color: selected ? const Color(0xFF2250E8) : Colors.transparent,
            ),
            onSelected: (_) {
              context.read<JournalBloc>().add(UpdateCleanliness(option));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttachmentCard(JournalStudentsLoaded state) {
    return _sectionCard(
      title: 'Lampiran',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _showAttachmentOptions,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF7)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attachment_rounded,
                    color: Color(0xFF2250E8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.attachment == null
                          ? 'Tap untuk pilih foto atau dokumen'
                          : _fileNameFromPath(state.attachment!.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: state.attachment == null
                            ? const Color(0xFF8A93A8)
                            : const Color(0xFF121826),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.attachment != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    _attachmentIcon(state.attachment!.path),
                    color: const Color(0xFF2250E8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachmentTypeLabel(state.attachment!.path),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFDC2626),
                    ),
                    onPressed: () {
                      context.read<JournalBloc>().add(SetAttachment(null));
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF121826),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: Text(
                    'Kamera',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Ambil foto langsung',
                    style: GoogleFonts.inter(),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _takePhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: Text(
                    'Galeri',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih gambar dari galeri',
                    style: GoogleFonts.inter(),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_rounded),
                  title: Text(
                    'Dokumen/File',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'PDF, Word, Excel, PPT, ZIP, dan lainnya',
                    style: GoogleFonts.inter(),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 220),
                    );
                    if (!mounted) return;
                    _pickDocument();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _attachmentIcon(String path) {
    final ext = _fileExtension(path);
    if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) return Icons.image;
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx', 'csv'].contains(ext)) return Icons.table_chart;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow;
    if (['zip', 'rar'].contains(ext)) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  String _attachmentTypeLabel(String path) {
    final ext = _fileExtension(path).toUpperCase();
    if (ext.isEmpty) return 'File lampiran';
    return 'File $ext';
  }

  String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  String _fileNameFromPath(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    if (parts.isEmpty) return path;
    return parts.last;
  }
}
