import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// User model representing authenticated user data
@JsonSerializable()
class User extends Equatable {
  final int id;
  final String nip;
  final String name;
  final String role;

  @JsonKey(name: 'mata_pelajaran')
  final String? mataPelajaran;

  @JsonKey(name: 'wali_kelas')
  final String? waliKelas;

  @JsonKey(name: 'is_inval_piket')
  final bool isInvalPiket;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;

  const User({
    required this.id,
    required this.nip,
    required this.name,
    required this.role,
    this.mataPelajaran,
    this.waliKelas,
    required this.isInvalPiket,
    this.createdAt,
    this.updatedAt,
    this.profilePhotoUrl,
  });

  /// Factory constructor for creating a User from JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Convert User to JSON
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Check if user is Admin
  bool get isAdmin => role == 'Admin';

  /// Check if user is Guru (Teacher)
  bool get isGuru => role == 'Guru';

  /// Check if user is Guru BK (Counselor)
  bool get isGuruBK => role == 'Guru BK';

  /// Check if user is Wali Kelas (Homeroom Teacher)
  bool get isWaliKelas {
    final kelas = waliKelas?.trim();
    if (kelas == null || kelas.isEmpty || kelas == '-') return false;
    return kelas.toUpperCase() != 'ALL';
  }

  /// Check if user has access to all classes
  bool get hasAccessToAllClasses => waliKelas?.trim().toUpperCase() == 'ALL';

  /// Get list of subjects taught by the teacher
  List<String> get subjects {
    if (mataPelajaran == null || mataPelajaran!.isEmpty) return [];
    return mataPelajaran!.split(';').map((s) => s.trim()).toList();
  }

  /// Display name for UI
  String get displayName => name;

  /// Short name (first name only)
  String get shortName {
    final parts = name.split(' ');
    return parts.first;
  }

  @override
  List<Object?> get props => [
    id,
    nip,
    name,
    role,
    mataPelajaran,
    waliKelas,
    isInvalPiket,
    createdAt,
    updatedAt,
    profilePhotoUrl,
  ];

  /// Copy with method for creating modified copies
  User copyWith({
    int? id,
    String? nip,
    String? name,
    String? role,
    String? mataPelajaran,
    String? waliKelas,
    bool? isInvalPiket,
    String? createdAt,
    String? updatedAt,
    String? profilePhotoUrl,
  }) {
    return User(
      id: id ?? this.id,
      nip: nip ?? this.nip,
      name: name ?? this.name,
      role: role ?? this.role,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      waliKelas: waliKelas ?? this.waliKelas,
      isInvalPiket: isInvalPiket ?? this.isInvalPiket,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }
}
