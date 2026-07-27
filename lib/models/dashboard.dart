// dashboard.dart

class DashboardData {
  const DashboardData({
    required this.user,
    required this.overview,
  });

  final DashboardUser user;
  final DashboardOverview overview;

  factory DashboardData.fromJson(
      Map<String, dynamic> json,
      ) {
    final dynamic rawUser = json['user'];
    final dynamic rawOverview = json['overview'];

    if (rawUser is! Map || rawOverview is! Map) {
      throw const FormatException(
        'The dashboard response has an invalid structure.',
      );
    }

    return DashboardData(
      user: DashboardUser.fromJson(
        Map<String, dynamic>.from(rawUser),
      ),
      overview: DashboardOverview.fromJson(
        Map<String, dynamic>.from(rawOverview),
      ),
    );
  }
}

class DashboardUser {
  const DashboardUser({
    required this.id,
    required this.coachId,
    required this.fullName,
    required this.role,
    required this.roleLabel,
    required this.initial,
  });

  final int id;
  final int? coachId;
  final String fullName;
  final String role;
  final String roleLabel;
  final String initial;

  bool get isAdmin => role == 'admin';

  factory DashboardUser.fromJson(
      Map<String, dynamic> json,
      ) {
    final String fullName =
        json['full_name']?.toString().trim() ?? '';

    final String role =
        json['role']?.toString().trim().toLowerCase() ?? '';

    final String initialFromApi =
        json['initial']?.toString().trim() ?? '';

    return DashboardUser(
      id: _requiredInt(json['id'], 'user.id'),
      coachId: _nullableInt(json['coach_id']),
      fullName: fullName.isEmpty ? 'User' : fullName,
      role: role,
      roleLabel:
      json['role_label']?.toString().trim().isNotEmpty == true
          ? json['role_label'].toString().trim()
          : role == 'admin'
          ? 'Administrator'
          : 'Coach',
      initial: initialFromApi.isNotEmpty
          ? initialFromApi
          : _firstCharacter(fullName),
    );
  }
}

class DashboardOverview {
  const DashboardOverview({
    required this.date,
    required this.players,
    required this.sessions,
    required this.attendancePercentage,
    required this.attendanceAttended,
    required this.attendanceCounted,
    required this.evaluations,
  });

  final String date;
  final int players;
  final int sessions;
  final double? attendancePercentage;
  final int attendanceAttended;
  final int attendanceCounted;
  final int evaluations;

  factory DashboardOverview.fromJson(
      Map<String, dynamic> json,
      ) {
    return DashboardOverview(
      date: json['date']?.toString() ?? '',
      players: _intOrZero(json['players']),
      sessions: _intOrZero(json['sessions']),
      attendancePercentage:
      _nullableDouble(json['attendance_percentage']),
      attendanceAttended:
      _intOrZero(json['attendance_attended']),
      attendanceCounted:
      _intOrZero(json['attendance_counted']),
      evaluations: _intOrZero(json['evaluations']),
    );
  }
}

int _requiredInt(dynamic value, String field) {
  final int? parsed = _nullableInt(value);

  if (parsed == null) {
    throw FormatException('$field must be an integer.');
  }

  return parsed;
}

int _intOrZero(dynamic value) {
  return _nullableInt(value) ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString());
}

String _firstCharacter(String value) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    return 'U';
  }

  return normalized.substring(0, 1).toUpperCase();
}
