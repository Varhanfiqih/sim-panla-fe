# Use Case Diagram SIM PANLA

Diagram dipisahkan menjadi dua berkas:

1. `use-case-mobile-apps.drawio`
2. `use-case-website-panel.drawio`

## Aktor Mobile Apps

- **Guru Mapel**: login, dashboard, notifikasi, profil, check-in, jadwal, presensi QR, jurnal, tugas inval, dan logout.
- **Wali Kelas**: spesialisasi Guru Mapel yang dapat mengelola izin dan nilai siswa.
- **Guru BK**: dashboard BK, monitoring absensi, konfirmasi ketidakhadiran, verifikasi izin, tindak lanjut, dan riwayat siswa.

Fitur inval pada Guru Mapel bersifat kondisional berdasarkan penugasan, bukan role pengguna yang terpisah.

## Aktor Website Panel

- **Super Admin**: seluruh pengelolaan data, monitoring, koreksi nilai/jurnal, dan ekspor laporan.
- **Admin IT**: pengelolaan data master, operasional, konfigurasi presensi, master penilaian, dan ekspor laporan.
- **Kepala Sekolah**: monitoring secara read-only dan ekspor laporan.

Catatan: Kepala Sekolah tidak dimodelkan sebagai pengelola data karena implementasi panel membatasi peran tersebut ke akses baca.
