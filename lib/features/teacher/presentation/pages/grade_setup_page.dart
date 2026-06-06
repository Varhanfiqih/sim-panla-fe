import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/grade_models.dart';
import '../../data/repositories/grade_repository.dart';
import 'grade_input_page.dart';

class GradeSetupPage extends StatefulWidget {
  const GradeSetupPage({super.key});

  @override
  State<GradeSetupPage> createState() => _GradeSetupPageState();
}

class _GradeSetupPageState extends State<GradeSetupPage> {
  final GradeRepository _repository = GradeRepository();

  bool _loading = true;
  GradeMeta? _meta;

  GradePeriod? _selectedPeriod;
  GradeSubject? _selectedSubject;
  GradeCategory? _selectedCategory;
  int _itemNo = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final meta = await _repository.getMeta();
      if (!mounted) return;

      final period = meta.periods.isEmpty
          ? null
          : meta.periods.firstWhere(
              (p) => p.id == meta.activePeriodId,
              orElse: () => meta.periods.first,
            );

      setState(() {
        _meta = meta;
        _selectedPeriod = period;
        _selectedSubject = meta.subjects.isEmpty ? null : meta.subjects.first;
        _selectedCategory = meta.categories.isEmpty
            ? null
            : meta.categories.first;
        _itemNo = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat setup penilaian: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF121826)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Setup Penilaian',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF121826),
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _meta == null
          ? const Center(child: Text('Data tidak tersedia'))
          : (_meta!.periods.isEmpty ||
                _meta!.subjects.isEmpty ||
                _meta!.categories.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Data master belum lengkap: ${_missingMasterDataLabel()}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
              children: [
                Text(
                  'SETUP PARAMETER',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF3B6AF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Konfigurasi Penilaian',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF121826),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 22),

                _buildFieldLabel('Periode Akademik'),
                const SizedBox(height: 8),
                _buildSelectCard<GradePeriod>(
                  icon: Icons.calendar_month_rounded,
                  value: _selectedPeriod,
                  items: _meta!.periods,
                  itemLabel: (e) => e.name,
                  onChanged: (v) => setState(() => _selectedPeriod = v),
                ),

                const SizedBox(height: 16),
                _buildFieldLabel('Kelas Terpilih'),
                const SizedBox(height: 8),
                _buildReadOnlyCard(
                  icon: Icons.school_rounded,
                  value: _meta!.classId,
                ),

                const SizedBox(height: 16),
                _buildFieldLabel('Mata Pelajaran'),
                const SizedBox(height: 8),
                _buildSelectCard<GradeSubject>(
                  icon: Icons.person_rounded,
                  value: _selectedSubject,
                  items: _meta!.subjects,
                  itemLabel: (e) => e.name,
                  onChanged: (v) => setState(() => _selectedSubject = v),
                ),

                const SizedBox(height: 16),
                _buildFieldLabel('Kategori Nilai'),
                const SizedBox(height: 8),
                _buildSelectCard<GradeCategory>(
                  icon: Icons.assignment_rounded,
                  value: _selectedCategory,
                  items: _meta!.categories,
                  itemLabel: (e) => e.name,
                  onChanged: (v) {
                    setState(() {
                      _selectedCategory = v;
                      _itemNo = 1;
                    });
                  },
                ),

                const SizedBox(height: 16),
                _buildFieldLabel('Nomor Item'),
                const SizedBox(height: 8),
                if (_selectedCategory?.isRepeatable ?? false)
                  _buildSelectCard<int>(
                    icon: Icons.format_list_numbered_rounded,
                    value: _itemNo,
                    items: List.generate(
                      _selectedCategory!.maxItem,
                      (i) => i + 1,
                    ),
                    itemLabel: (e) => '${_selectedCategory!.name} $e',
                    onChanged: (v) => setState(() => _itemNo = v ?? 1),
                  )
                else
                  _buildReadOnlyCard(
                    icon: Icons.format_list_numbered_rounded,
                    value: 'Item 1',
                  ),

                const SizedBox(height: 28),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        _selectedPeriod == null ||
                            _selectedSubject == null ||
                            _selectedCategory == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GradeInputPage(
                                  period: _selectedPeriod!,
                                  subject: _selectedSubject!,
                                  category: _selectedCategory!,
                                  itemNo: _itemNo,
                                  classId: _meta!.classId,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      backgroundColor: const Color(0xFF2250E8),
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Mulai Input Nilai',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF8A93A8),
      ),
    );
  }

  String _missingMasterDataLabel() {
    final missing = <String>[];
    if (_meta?.periods.isEmpty ?? true) missing.add('periode nilai');
    if (_meta?.subjects.isEmpty ?? true) missing.add('mata pelajaran');
    if (_meta?.categories.isEmpty ?? true) missing.add('kategori nilai');
    if (missing.isEmpty) return '-';
    return missing.join(', ');
  }

  Widget _buildReadOnlyCard({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2250E8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFA1A8BC),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCard<T>({
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFFA1A8BC),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFF2250E8), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          itemLabel(e),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
