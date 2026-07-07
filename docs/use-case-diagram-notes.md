# Use Case Diagram SIM PANLA

Diagram dipisahkan menjadi dua berkas:

1. `use-case-mobile-apps.drawio`
2. `use-case-website-panel.drawio`

## Dasar Penyesuaian

- Mobile apps disesuaikan dengan `sim-panla-backend/routes/api.php`, model user Flutter, dan halaman mobile pada `sim-panla-fe/lib/features`.
- Website panel disesuaikan dengan `User::canAccessPanel()`, helper role pada `User.php`, serta akses `canAccess()`, `canViewAny()`, `canCreate()`, `canEdit()`, dan `canDelete()` pada Filament Pages/Resources.
- `Guru Piket` tidak dibuat sebagai aktor karena pada kode `is_inval_piket` adalah status/penugasan, bukan role pengguna.
- Relasi `<<include>>` digunakan untuk subfitur yang selalu menjadi bagian dari use case utama.
- Relasi `<<extend>>` digunakan untuk fitur tambahan/kondisional. Jika disebut "exclude" dalam pembahasan, yang dimaksud pada UML adalah `<<extend>>`.

## Aktor Mobile Apps

- **Guru Mapel**: login, dashboard, notifikasi, profil, logout, check-in kehadiran, jadwal mengajar, QR presensi siswa, jurnal mengajar, riwayat jurnal, dan inval.
- **Wali Kelas**: spesialisasi Guru Mapel yang memiliki fitur tambahan untuk izin siswa dan nilai siswa. Validasi Wali Kelas berasal dari relasi `homeroomClass`.
- **Guru BK**: dashboard BK, monitoring absensi siswa, konfirmasi ketidakhadiran, verifikasi izin, tindak lanjut BK, riwayat siswa, serta beberapa fitur operasional bersama yang dibuka oleh endpoint Guru/Guru BK.
- Contoh `<<extend>>` mobile: input NISN manual memperluas scan QR, lampiran jurnal memperluas pengisian jurnal, dan inval memperluas jadwal mengajar jika ada penugasan.

## Aktor Website Panel

- **Super Admin**: akses web panel penuh untuk dashboard, master data, operasional, penilaian, monitoring, koreksi data tertentu, dan ekspor laporan.
- **Admin IT**: mengelola master data, operasional, konfigurasi presensi, master penilaian, dan ekspor laporan. Admin IT tidak dimodelkan sebagai pengelola jurnal/nilai siswa penuh karena resource terkait dibatasi di kode.
- **Kepala Sekolah**: akses web panel untuk dashboard, monitoring read-only, melihat laporan/data, dan ekspor laporan.
- Contoh `<<extend>>` web panel: hapus data master, koreksi nilai, dan koreksi jurnal hanya muncul pada kondisi/hak akses tertentu.

Catatan: Kepala Sekolah tidak dimodelkan sebagai pengelola data karena implementasi panel membatasi peran tersebut ke akses baca/read-only pada resource utama.
