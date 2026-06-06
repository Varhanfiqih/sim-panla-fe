// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  nip: json['nip'] as String,
  name: json['name'] as String,
  role: json['role'] as String,
  mataPelajaran: json['mata_pelajaran'] as String?,
  waliKelas: json['wali_kelas'] as String?,
  isInvalPiket: json['is_inval_piket'] as bool,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  profilePhotoUrl: json['profile_photo_url'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'nip': instance.nip,
  'name': instance.name,
  'role': instance.role,
  'mata_pelajaran': instance.mataPelajaran,
  'wali_kelas': instance.waliKelas,
  'is_inval_piket': instance.isInvalPiket,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'profile_photo_url': instance.profilePhotoUrl,
};
