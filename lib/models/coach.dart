// coach.dart
class CoachModel {
  const CoachModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    this.specialization,
    this.photo,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.groupsCount,
    this.playersCount,
  });

  final int id;
  final String fullName;
  final String phone;
  final String status;
  final String? specialization;
  final String? photo;
  final String? email;
  final String? createdAt;
  final String? updatedAt;
  final int? groupsCount;
  final int? playersCount;

  String get initial => fullName.isEmpty ? '?' : fullName[0].toUpperCase();

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    return CoachModel(
      id: _asInt(json['id']) ?? 0,
      fullName: _asString(json['full_name'] ?? json['name']) ?? '-',
      phone: _asString(json['phone'] ?? json['phone_number']) ?? '-',
      status: (_asString(json['status']) ?? 'active').toLowerCase(),
      specialization: _asString(json['specialization']),
      photo: _asString(json['photo']),
      email: _asString(json['email']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
      groupsCount: _asInt(json['groups_count']),
      playersCount: _asInt(json['players_count']),
    );
  }

  CoachModel copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? status,
    String? specialization,
    String? photo,
    String? email,
    String? createdAt,
    String? updatedAt,
    int? groupsCount,
    int? playersCount,
  }) {
    return CoachModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      specialization: specialization ?? this.specialization,
      photo: photo ?? this.photo,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      groupsCount: groupsCount ?? this.groupsCount,
      playersCount: playersCount ?? this.playersCount,
    );
  }
}

class CoachInput {
  const CoachInput({
    required this.fullName,
    required this.phone,
    required this.status,
    this.specialization,
    this.email,
    this.photo,
    this.password,
  });

  final String fullName;
  final String phone;
  final String status;
  final String? specialization;
  final String? email;
  final String? photo;
  final String? password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'status': status,
      'specialization': _nullableTrim(specialization),
      'email': _nullableTrim(email),
      'photo': _nullableTrim(photo),
      if (password != null && password!.trim().isNotEmpty)
        'password': password!.trim(),
    };
  }
}

String? _nullableTrim(String? value) {
  if (value == null) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final String result = value.toString().trim();
  return result.isEmpty ? null : result;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
