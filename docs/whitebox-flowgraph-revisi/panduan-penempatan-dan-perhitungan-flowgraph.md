# Penempatan dan Perhitungan Flow Graph White Box Testing

Acuan metode flow graph mengacu pada Pressman pada pembahasan White-Box Testing, Basis Path Testing, Flow Graph Notation, dan Cyclomatic Complexity. Pressman menjelaskan bahwa basis path testing menggunakan flow graph untuk menggambarkan alur kontrol logika program. Nilai cyclomatic complexity digunakan untuk menentukan jumlah jalur independen yang perlu diuji. Rumus yang digunakan adalah V(G) = E - N + 2 atau V(G) = P + 1, dengan E sebagai jumlah edge, N sebagai jumlah node, dan P sebagai jumlah predicate node.

## Ringkasan Penempatan

| Iterasi | Flow Graph | Diletakkan pada Bagian | V(G) |
|---|---|---|---|
| Iterasi 1 | Flow Graph Login Web Panel | 5.1.1.3 White Box Testing - Login Web Panel | 3 |
| Iterasi 2 | Flow Graph Kelola Jadwal Pelajaran | 5.1.2.3 White Box Testing - Kelola Jadwal Pelajaran | 3 |
| Iterasi 3 | Flow Graph Presensi Kehadiran Guru | 5.1.3.3 White Box Testing - Presensi Kehadiran Guru | 3 |
| Iterasi 4 | Flow Graph Pengajuan Izin Siswa | 5.1.4.3 White Box Testing - Pengajuan Izin Siswa oleh Wali Kelas | 3 |
| Iterasi 5 | Flow Graph Verifikasi Izin Siswa Guru BK | 5.1.5.3 White Box Testing - Verifikasi Izin Siswa oleh Guru BK | 3 |

## Iterasi 1 - Flow Graph Login Web Panel

**File gambar:** `iterasi-1-flowgraph-login-web-panel.png`

**Penempatan:** Diletakkan setelah uraian pengujian white box Login Web Panel, sebelum atau sesudah gambar hasil Pest login web panel.

### Perhitungan Cyclomatic Complexity

```text
Predicate Node (P) = 2
Node (N) = 10
Edge (E) = 11
V(G) = E - N + 2 = 11 - 10 + 2 = 3
V(G) = P + 1 = 2 + 1 = 3
Jumlah jalur independen = 3
```

### Jalur Independen

1. Path 1: Mulai -> input NIP/password -> validasi akun -> akun tidak valid -> tampilkan pesan gagal -> selesai.
2. Path 2: Mulai -> input NIP/password -> validasi akun -> akun valid -> role tidak boleh akses web -> tampilkan akses ditolak -> selesai.
3. Path 3: Mulai -> input NIP/password -> validasi akun -> akun valid -> role boleh akses web -> buat session dan role -> arahkan dashboard -> selesai.

## Iterasi 2 - Flow Graph Kelola Jadwal Pelajaran

**File gambar:** `iterasi-2-flowgraph-kelola-jadwal-pelajaran.png`

**Penempatan:** Diletakkan pada bagian Kelola Jadwal Pelajaran setelah narasi skenario pengujian white box jadwal.

### Perhitungan Cyclomatic Complexity

```text
Predicate Node (P) = 2
Node (N) = 10
Edge (E) = 11
V(G) = E - N + 2 = 11 - 10 + 2 = 3
V(G) = P + 1 = 2 + 1 = 3
Jumlah jalur independen = 3
```

### Jalur Independen

1. Path 1: Mulai -> input data jadwal -> validasi kelas/mapel/guru/jam -> data tidak valid -> tampilkan error validasi -> selesai.
2. Path 2: Mulai -> input data jadwal -> data valid -> terjadi bentrok jadwal -> tampilkan error bentrok -> selesai.
3. Path 3: Mulai -> input data jadwal -> data valid -> tidak bentrok -> simpan jadwal -> tampilkan jadwal terbaru -> selesai.

## Iterasi 3 - Flow Graph Presensi Kehadiran Guru

**File gambar:** `iterasi-3-flowgraph-presensi-kehadiran-guru.png`

**Penempatan:** Diletakkan pada bagian Presensi Kehadiran Guru setelah penjelasan validasi status hadir/tidak hadir.

### Perhitungan Cyclomatic Complexity

```text
Predicate Node (P) = 2
Node (N) = 8
Edge (E) = 9
V(G) = E - N + 2 = 9 - 8 + 2 = 3
V(G) = P + 1 = 2 + 1 = 3
Jumlah jalur independen = 3
```

### Jalur Independen

1. Path 1: Mulai -> input status hadir -> status tidak hadir -> alasan tidak diisi -> tampilkan error alasan -> selesai.
2. Path 2: Mulai -> input status hadir -> status tidak hadir -> alasan diisi -> simpan teacher attendance -> kirim notifikasi check-in -> tampilkan berhasil -> selesai.
3. Path 3: Mulai -> input status hadir -> status hadir -> simpan teacher attendance -> kirim notifikasi check-in -> tampilkan berhasil -> selesai.

## Iterasi 4 - Flow Graph Pengajuan Izin Siswa

**File gambar:** `iterasi-4-flowgraph-pengajuan-izin-siswa.png`

**Penempatan:** Diletakkan pada bagian Pengajuan Izin Siswa oleh Wali Kelas, setelah narasi validasi siswa, tanggal izin, dan pembatasan kelas wali.

### Perhitungan Cyclomatic Complexity

```text
Predicate Node (P) = 2
Node (N) = 10
Edge (E) = 11
V(G) = E - N + 2 = 11 - 10 + 2 = 3
V(G) = P + 1 = 2 + 1 = 3
Jumlah jalur independen = 3
```

### Jalur Independen

1. Path 1: Mulai -> input data izin siswa -> validasi field/tanggal -> data tidak valid -> tampilkan error validasi -> selesai.
2. Path 2: Mulai -> input data izin siswa -> data valid -> siswa bukan kelas wali -> tampilkan akses ditolak -> selesai.
3. Path 3: Mulai -> input data izin siswa -> data valid -> siswa kelas wali -> simpan izin pending -> tampilkan berhasil -> selesai.

## Iterasi 5 - Flow Graph Verifikasi Izin Siswa Guru BK

**File gambar:** `iterasi-5-flowgraph-verifikasi-izin-siswa.png`

**Penempatan:** Diletakkan pada bagian Verifikasi Izin Siswa oleh Guru BK setelah penjelasan proses approve/reject izin.

### Perhitungan Cyclomatic Complexity

```text
Predicate Node (P) = 2
Node (N) = 10
Edge (E) = 11
V(G) = E - N + 2 = 11 - 10 + 2 = 3
V(G) = P + 1 = 2 + 1 = 3
Jumlah jalur independen = 3
```

### Jalur Independen

1. Path 1: Mulai -> pilih pengajuan izin -> validasi role Guru BK -> role tidak valid -> tampilkan akses ditolak -> selesai.
2. Path 2: Mulai -> pilih pengajuan izin -> role valid -> keputusan rejected -> update status rejected -> kirim notifikasi hasil -> selesai.
3. Path 3: Mulai -> pilih pengajuan izin -> role valid -> keputusan approved -> update status approved -> sinkronkan catatan siswa -> kirim notifikasi hasil -> selesai.
