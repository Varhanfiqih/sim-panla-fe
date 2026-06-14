import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../bloc/bloc.dart';
import '../../data/models/qr_scan.dart';

/// QR Scanner Page - Following stitch design (s_09_qr_scanner)
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  bool _isFrontCamera = false;
  bool _isSwitchingCamera = false;

  // Colors from stitch design
  static const Color _primary = Color(0xFF0040DF);
  static const Color _primaryContainer = Color(0xFF2D5BFF);
  static const Color _surface = Color(0xFFFAF8FF);
  static const Color _surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF434655);
  static const Color _outline = Color(0xFF737686);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: false, // Prevents camera from starting automatically
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScannerState();
    });

    // Load categories on init
    context.read<QrScanBloc>().add(const LoadCategories());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QrScannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncScannerState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      _syncScannerState();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _scannerController.stop();
    }
  }

  void _syncScannerState() {
    if (!mounted) return;

    if (widget.isActive) {
      _scannerController.start();
    } else {
      _scannerController.stop();
    }
  }

  Future<void> _switchCamera(QrScanState state) async {
    if (_isSwitchingCamera) return;

    setState(() => _isSwitchingCamera = true);

    try {
      if (state is QrScanReady && state.flashlightOn) {
        await _scannerController.toggleTorch();
        if (mounted) {
          context.read<QrScanBloc>().add(const ToggleFlashlight());
        }
      }

      await _scannerController.switchCamera();

      if (mounted) {
        setState(() => _isFrontCamera = !_isFrontCamera);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera depan tidak tersedia pada perangkat ini.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSwitchingCamera = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrScanBloc, QrScanState>(
      listener: (context, state) {
        // Show success snackbar
        if (state is QrScanSuccess) {
          final qrScanBloc = context.read<QrScanBloc>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.response.message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Auto continue scanning after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              qrScanBloc.add(const ClearScanResult());
            }
          });
        }

        // Show error snackbar
        if (state is QrScanError) {
          final qrScanBloc = context.read<QrScanBloc>();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFDC2626), // red-600
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Auto clear error after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              qrScanBloc.add(const ClearScanResult());
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: _surface,
        body: BlocBuilder<QrScanBloc, QrScanState>(
          builder: (context, state) {
            if (state is QrScanCategoriesLoading || state is QrScanInitial) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }

            if (state is QrScanCategoriesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gagal memuat kategori',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<QrScanBloc>().add(const LoadCategories());
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                // Camera viewport
                _buildCameraView(state),

                // Top app bar
                _buildTopAppBar(),

                // Bottom controls
                _buildBottomControls(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraView(QrScanState state) {
    final bool canProcess = state is QrScanReady;
    final bool showLoadingOverlay = state is QrScanProcessing;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height:
          MediaQuery.of(context).size.height * 0.6, // Only top 60% of screen
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera feed always rendered
          MobileScanner(
            controller: _scannerController,
            errorBuilder: (context, error, child) {
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_off_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kamera tidak bisa diakses',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cek izin kamera lalu buka ulang halaman scanner.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              if (!canProcess) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  context.read<QrScanBloc>().add(ProcessScan(code));
                }
              }
            },
          ),

          if (showLoadingOverlay)
            Container(
              color: Colors.black.withAlpha(150),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Scan UI (Overlay and Instruction)
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 220), // Adjusted size
                    painter: ScanFramePainter(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Arahkan QR Code dalam frame',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        const Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Camera controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 24,
            child: Column(
              children: [
                _buildCameraSwitchButton(state),
                if (!_isFrontCamera) ...[
                  const SizedBox(height: 12),
                  _buildFlashlightButton(state),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(179), // 0.7 opacity
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF131B2E).withAlpha(15),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _primary.withAlpha(26),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: _primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Text(
                    'QR Scanner',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: _onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashlightButton(QrScanState state) {
    bool flashOn = false;
    if (state is QrScanReady) {
      flashOn = state.flashlightOn;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<QrScanBloc>().add(const ToggleFlashlight());
          _scannerController.toggleTorch();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26), // 0.1 opacity
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withAlpha(51), // 0.2 opacity
              width: 1,
            ),
          ),
          child: Icon(
            flashOn ? Icons.flash_on : Icons.flash_off,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraSwitchButton(QrScanState state) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSwitchingCamera ? null : () => _switchCamera(state),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(51), width: 1),
          ),
          child: _isSwitchingCamera
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _isFrontCamera
                      ? Icons.camera_rear_rounded
                      : Icons.camera_front_rounded,
                  color: Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(QrScanState state) {
    List<ActivityGroup> activities = [];
    ActivityGroup? selectedActivity;
    AttendanceCategory? selectedCategory;
    ScanResultData? lastScan;
    List<ScanHistoryItem> recentScans = [];

    if (state is QrScanReady) {
      activities = state.activities;
      selectedActivity = state.selectedActivity;
      selectedCategory = state.selectedCategory;
      recentScans = state.recentScans;
    } else if (state is QrScanProcessing) {
      activities = state.activities;
      selectedActivity = state.selectedActivity;
      selectedCategory = state.selectedCategory;
    } else if (state is QrScanSuccess) {
      activities = state.activities;
      selectedActivity = state.selectedActivity;
      selectedCategory = state.selectedCategory;
      lastScan = state.response.data;
      recentScans = state.recentScans;
    } else if (state is QrScanError) {
      activities = state.activities;
      selectedActivity = state.selectedActivity;
      selectedCategory = state.selectedCategory;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).padding.bottom +
                    60, // Reduced space for bottom nav
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(
                  179,
                ), // Restored glassmorphism effect
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFC3C6D7).withAlpha(51),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 40,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bottom sheet drag handle indicator
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(100),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Selected Activity Dropdown
                    Text(
                      'SELECTED ACTIVITY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: _outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ActivityGroup>(
                          isExpanded: true,
                          value: selectedActivity,
                          icon: const Icon(Icons.expand_more, color: _primary),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _onSurface,
                          ),
                          onChanged: (ActivityGroup? newValue) {
                            if (newValue != null) {
                              context.read<QrScanBloc>().add(
                                SelectActivity(newValue),
                              );
                            }
                          },
                          items: activities
                              .map<DropdownMenuItem<ActivityGroup>>((
                                ActivityGroup value,
                              ) {
                                return DropdownMenuItem<ActivityGroup>(
                                  value: value,
                                  child: Text(value.activity),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category selection
                    Text(
                      'SCAN TYPE MODE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: _outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          ...(selectedActivity?.scanTypes.map((category) {
                                final bool isSelected =
                                    selectedCategory?.id == category.id;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildCategoryChip(
                                    label: category.name,
                                    isSelected: isSelected,
                                    onTap: () {
                                      context.read<QrScanBloc>().add(
                                        SelectCategory(category),
                                      );
                                    },
                                  ),
                                );
                              }).toList() ??
                              []),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state is QrScanReady
                            ? () => _showManualNisnDialog(context)
                            : null,
                        icon: const Icon(Icons.keyboard_alt_outlined),
                        label: const Text('Ketik NISN Manual'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Last scan result
                    if (lastScan != null && lastScan.student != null) ...[
                      const SizedBox(height: 24),
                      _buildScanResult(lastScan),
                    ],

                    // Recent scans (if any)
                    if (recentScans.isNotEmpty && lastScan == null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'RIWAYAT TERAKHIR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: _outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...recentScans.map(
                        (scan) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildHistoryItem(scan),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showManualNisnDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var inputNisn = '';
    final qrScanBloc = context.read<QrScanBloc>();

    await _scannerController.stop();

    if (!context.mounted) return;

    final nisn = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Input NISN Siswa'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'NISN',
              hintText: 'Masukkan 8-10 digit NISN',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (value) {
              final input = value?.trim() ?? '';
              if (input.isEmpty) return 'NISN wajib diisi';
              if (input.length < 8 || input.length > 10) {
                return 'NISN harus terdiri dari 8-10 digit';
              }
              return null;
            },
            onChanged: (value) => inputNisn = value.trim(),
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, inputNisn);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, inputNisn);
              }
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Proses'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    _syncScannerState();

    if (nisn != null) {
      qrScanBloc.add(ProcessScan(nisn));
    }
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          constraints: const BoxConstraints(minHeight: 36),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _primaryContainer],
                  )
                : null,
            color: isSelected ? null : _surfaceContainerHigh,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primary.withAlpha(51), // 0.2 opacity
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : _onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanResult(ScanResultData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981), // emerald-500
          width: 4,
        ),
      ),
      child: Row(
        children: [
          // Student avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                data.student!.name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.student!.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5), // emerald-100
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'VERIFIED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: const Color(0xFF047857), // emerald-700
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.student!.className ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _outline,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFF10B981), // emerald-500
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Check-in Success ${data.scannedAt ?? ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ScanHistoryItem scan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest.withAlpha(153), // 0.6 opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 20, color: _outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.student.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
                Text(
                  '${scan.category} • ${scan.scannedAt}',
                  style: GoogleFonts.inter(fontSize: 11, color: _outline),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: _outline),
        ],
      ),
    );
  }
}

/// Custom painter for scan frame with rounded corners
class ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0040DF)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const double cornerLength = 40;
    const double cornerRadius = 24;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerRadius)
        ..arcToPoint(
          const Offset(cornerRadius, 0),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - cornerRadius, 0)
        ..arcToPoint(
          Offset(size.width, cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - cornerRadius)
        ..arcToPoint(
          Offset(cornerRadius, size.height),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - cornerRadius, size.height)
        ..arcToPoint(
          Offset(size.width, size.height - cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
