class PlayerModel {
  final String id;
  final String name;
  final String code;
  final String phone;
  final String group;
  final int age;
  final double attendance;
  final PlayerStatus status;
  final String medicalNotes;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.code,
    required this.phone,
    required this.group,
    required this.age,
    required this.attendance,
    required this.status,
    required this.medicalNotes,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'].toString(),
      name: json['full_name'] ?? '',
      code: json['player_code'] ?? '',
      phone: json['phone'] ?? '',
      group: json['group_name'] ?? '',
      medicalNotes: json['medical_notes'] ?? '',
      age: _calculateAge(json['birth_date']),
      attendance:
      double.tryParse(json['attendance_percentage']?.toString() ?? '0') ??
          0.0,
      status: _parseStatus(json['status']),
    );
  }

  static PlayerStatus _parseStatus(dynamic value) {
    switch (value.toString().toLowerCase()) {
      case 'active':
        return PlayerStatus.active;

      case 'inactive':
        return PlayerStatus.inactive;

      default:
        return PlayerStatus.pending;
    }
  }

  static int _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 0;

    final dob = DateTime.tryParse(birthDate);

    if (dob == null) return 0;

    final now = DateTime.now();

    int age = now.year - dob.year;

    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    return age;
  }
}

enum PlayerStatus {
  active,
  inactive,
  pending,
}

extension PlayerStatusLabel on PlayerStatus {
  String get label {
    switch (this) {
      case PlayerStatus.active:
        return 'Active';

      case PlayerStatus.inactive:
        return 'Inactive';

      case PlayerStatus.pending:
        return 'Pending';
    }
  }
}