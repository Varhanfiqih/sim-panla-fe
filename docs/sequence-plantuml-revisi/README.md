# Revisi Sequence Diagram PlantUML

Seluruh file `.puml` pada folder ini dibuat ulang tanpa participant/lifeline `Database MySQL`.

## Iterasi 1

1. `gambar-4-23-sequence-login-web-panel.puml`
2. `gambar-4-24-sequence-dashboard-super-admin.puml`
3. `gambar-4-25-sequence-kelola-data-master.puml`
4. `gambar-4-26-sequence-kelola-data-siswa-dan-kelas.puml`

## Iterasi 2

1. `gambar-4-31-sequence-monitoring-izin-siswa-dan-penugasan-inval.puml`
2. `gambar-4-32-sequence-kelola-nilai-dan-pengaturan-presensi.puml`
3. `gambar-4-33-sequence-monitoring-laporan.puml`
4. `gambar-4-34-sequence-export-laporan.puml`

## Iterasi 3

1. `gambar-4-40-sequence-login-guru-mapel.puml`
2. `gambar-4-41-sequence-check-in-kehadiran-guru.puml`
3. `gambar-4-42-sequence-qr-scan-absensi-siswa.puml`
4. `gambar-4-43-sequence-jurnal-kbm.puml`
5. `gambar-4-44-sequence-klaim-inval-kelas-guru-mapel.puml`

## Iterasi 4

1. `gambar-4-49-sequence-login-guru-wali-kelas.puml`
2. `gambar-4-50-sequence-klaim-inval-kelas-wali-kelas.puml`
3. `gambar-4-51-sequence-input-izin-siswa.puml`
4. `gambar-4-52-sequence-input-nilai-siswa.puml`

## Iterasi 5

1. `gambar-4-57-sequence-login-guru-bk.puml`
2. `gambar-4-58-sequence-klaim-inval-kelas-guru-bk.puml`
3. `gambar-4-59-sequence-pertindakan-siswa.puml`
4. `gambar-4-60-sequence-verifikasi-izin-siswa.puml`

## Render

Jika PlantUML sudah tersedia, render semua file dengan perintah:

```bash
plantuml -tpng *.puml
```

atau untuk SVG:

```bash
plantuml -tsvg *.puml
```
