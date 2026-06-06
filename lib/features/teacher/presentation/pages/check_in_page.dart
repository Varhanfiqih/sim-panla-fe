import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/bloc.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  // Design tokens dari stitch
  static const Color _primary = Color(0xFF0040DF);
  static const Color _primaryContainer = Color(0xFF2D5BFF);
  static const Color _surface = Color(0xFFFAF8FF);
  static const Color _surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF434655);
  static const Color _outlineVariant = Color(0xFFC3C6D7);

  String? _selectedStatus; // 'hadir' or 'tidak_hadir'
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();

  final List<Map<String, String>> _absenceReasons = [
    {'value': 'Sakit', 'label': 'Sakit'},
    {'value': 'Izin', 'label': 'Izin'},
    {'value': 'Dinas Luar', 'label': 'Dinas Luar'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withAlpha(102), // 0.4 opacity overlay
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping sheet
            child: DraggableScrollableSheet(
              initialChildSize: _selectedStatus == 'tidak_hadir' ? 0.85 : 0.65,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _onSurface.withValues(alpha: 0.15),
                        blurRadius: 60,
                        offset: const Offset(0, -20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _outlineVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          children: [
                            // Header
                            _buildHeader(),
                            const SizedBox(height: 24),

                            // Attendance Options - Vertical Stack
                            _buildAttendanceOptions(),

                            // Conditional Form for Izin/Sakit
                            if (_selectedStatus == 'tidak_hadir') ...[
                              const SizedBox(height: 16),
                              _buildAbsenceForm(),
                            ],

                            // Submit button for Hadir
                            if (_selectedStatus == 'hadir') ...[
                              const SizedBox(height: 24),
                              _buildSubmitButton(),
                            ],

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Presensi Guru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAttendanceOptions() {
    return Column(
      children: [
        // Hadir Option
        _buildOptionCard(
          status: 'hadir',
          title: 'Hadir',
          subtitle: 'Siap memulai sesi mengajar',
          gradientColors: const [
            Color(0xFF4ADE80),
            Color(0xFF22C55E),
          ], // green-400 to green-500
          icon: Icons.check_circle,
        ),
        const SizedBox(height: 16),

        // Izin/Sakit Option
        _buildOptionCard(
          status: 'tidak_hadir',
          title: 'Izin/Sakit',
          subtitle: 'Tidak dapat mengajar hari ini',
          gradientColors: const [
            Color(0xFFFB923C),
            Color(0xFFEF4444),
          ], // orange-400 to red-500
          icon: Icons.cancel,
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String status,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(179), // glass effect
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primary : Colors.white.withAlpha(102),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primary.withAlpha(51), // 0.2 opacity
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withAlpha(77), // 0.3 opacity
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _outlineVariant.withAlpha(26), // 0.1 opacity
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reason Dropdown
          _buildLabel('REASON FOR ABSENCE'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'Select a reason...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _outlineVariant,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _onSurface,
              ),
              icon: Icon(Icons.expand_more, color: _onSurfaceVariant),
              items: _absenceReasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason['value'],
                  child: Text(reason['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          // Description TextField
          _buildLabel('DESCRIPTION'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Please provide additional details here...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _outlineVariant.withAlpha(128),
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _onSurface,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bool canSubmit =
        _selectedStatus == 'hadir' ||
        (_selectedStatus == 'tidak_hadir' && _selectedReason != null);

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: canSubmit
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryContainer],
                )
              : null,
          color: canSubmit ? null : _outlineVariant,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canSubmit
              ? [
                  BoxShadow(
                    color: _primary.withAlpha(51), // 0.2 opacity
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: canSubmit ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'Submit Attendance Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: _onSurfaceVariant,
      ),
    );
  }

  void _handleSubmit() {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih status kehadiran terlebih dahulu',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedStatus == 'tidak_hadir' && _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih alasan ketidakhadiran terlebih dahulu',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Submit to BLoC
    context.read<AttendanceBloc>().add(
      SubmitCheckIn(
        status: _selectedStatus!,
        reason: _selectedReason,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      ),
    );

    // Close bottom sheet and return success flag
    Navigator.pop(context, true);
  }
}
