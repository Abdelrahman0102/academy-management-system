class PlayerModel {
  const PlayerModel({
    required this.id,
    required this.code,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.status,
    this.photo,
    this.medicalNotes,
    this.createdAt,
    this.updatedAt,
    this.age,
    this.parentId,
    this.parentName,
    this.parentPhone,
    this.parentRelationship,
    this.groupId,
    this.group,
    this.groupLevel,
    this.schedule,
    this.coachName,
    this.attendance,
    this.sessionsAttended,
    this.sessionsMissed,
    this.totalEvaluations,
    this.evaluationRating,
    this.latestCoachNote,
    this.latestTechnical,
    this.latestPhysical,
    this.latestDiscipline,
    this.latestTeamwork,
    this.latestOverall,
    this.latestEvaluationCreatedAt,
  });

  final int id;
  final String code;
  final String name;
  final String birthDate;
  final String gender;
  final String status;
  final String? photo;
  final String? medicalNotes;
  final String? createdAt;
  final String? updatedAt;
  final int? age;

  final int? parentId;
  final String? parentName;
  final String? parentPhone;
  final String? parentRelationship;

  final int? groupId;
  final String? group;
  final String? groupLevel;
  final String? schedule;
  final String? coachName;

  final double? attendance;
  final int? sessionsAttended;
  final int? sessionsMissed;
  final int? totalEvaluations;
  final double? evaluationRating;
  final String? latestCoachNote;
  final double? latestTechnical;
  final double? latestPhysical;
  final double? latestDiscipline;
  final double? latestTeamwork;
  final double? latestOverall;
  final String? latestEvaluationCreatedAt;

  String get initial =>
      name.isEmpty ? '?' : name[0].toUpperCase();

  String get phone => parentPhone ?? '';

  factory PlayerModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return PlayerModel(
      id: _asInt(json['id']) ?? 0,
      code: _asString(
        json['player_code'] ?? json['code'],
      ) ??
          '-',
      name: _asString(
        json['full_name'] ?? json['name'],
      ) ??
          '-',
      birthDate:
      _asString(json['birth_date']) ?? '-',
      gender: _asString(json['gender']) ?? '-',
      status:
      (_asString(json['status']) ?? 'inactive')
          .toLowerCase(),
      photo: _asString(json['photo']),
      medicalNotes:
      _asString(json['medical_notes']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
      age: _asInt(json['age']),
      parentId: _asInt(json['parent_id']),
      parentName: _asString(json['parent_name']),
      parentPhone: _asString(
        json['parent_phone'] ?? json['phone'],
      ),
      parentRelationship:
      _asString(json['parent_relationship']),
      groupId: _asInt(json['group_id']),
      group: _asString(
        json['group_name'] ?? json['group'],
      ),
      groupLevel:
      _asString(json['group_level']),
      schedule: _asString(json['schedule']),
      coachName: _asString(json['coach_name']),
      attendance: _asDouble(json['attendance']),
      sessionsAttended:
      _asInt(json['sessions_attended']),
      sessionsMissed:
      _asInt(json['sessions_missed']),
      totalEvaluations:
      _asInt(json['total_evaluations']),
      evaluationRating: _asDouble(
        json['evaluation_rating'] ??
            json['rating_out_of_5'],
      ),
      latestCoachNote:
      _asString(json['latest_coach_note']),
      latestTechnical:
      _asDouble(json['latest_technical']),
      latestPhysical:
      _asDouble(json['latest_physical']),
      latestDiscipline:
      _asDouble(json['latest_discipline']),
      latestTeamwork:
      _asDouble(json['latest_teamwork']),
      latestOverall:
      _asDouble(json['latest_overall']),
      latestEvaluationCreatedAt: _asString(
        json['latest_evaluation_created_at'],
      ),
    );
  }

  PlayerModel copyWith({
    int? id,
    String? code,
    String? name,
    String? birthDate,
    String? gender,
    String? status,
    String? photo,
    String? medicalNotes,
    String? createdAt,
    String? updatedAt,
    int? age,
    int? parentId,
    String? parentName,
    String? parentPhone,
    String? parentRelationship,
    int? groupId,
    String? group,
    String? groupLevel,
    String? schedule,
    String? coachName,
    double? attendance,
    int? sessionsAttended,
    int? sessionsMissed,
    int? totalEvaluations,
    double? evaluationRating,
    String? latestCoachNote,
    double? latestTechnical,
    double? latestPhysical,
    double? latestDiscipline,
    double? latestTeamwork,
    double? latestOverall,
    String? latestEvaluationCreatedAt,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      photo: photo ?? this.photo,
      medicalNotes:
      medicalNotes ?? this.medicalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      age: age ?? this.age,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentPhone:
      parentPhone ?? this.parentPhone,
      parentRelationship:
      parentRelationship ??
          this.parentRelationship,
      groupId: groupId ?? this.groupId,
      group: group ?? this.group,
      groupLevel:
      groupLevel ?? this.groupLevel,
      schedule: schedule ?? this.schedule,
      coachName: coachName ?? this.coachName,
      attendance: attendance ?? this.attendance,
      sessionsAttended:
      sessionsAttended ??
          this.sessionsAttended,
      sessionsMissed:
      sessionsMissed ?? this.sessionsMissed,
      totalEvaluations:
      totalEvaluations ??
          this.totalEvaluations,
      evaluationRating:
      evaluationRating ??
          this.evaluationRating,
      latestCoachNote:
      latestCoachNote ??
          this.latestCoachNote,
      latestTechnical:
      latestTechnical ??
          this.latestTechnical,
      latestPhysical:
      latestPhysical ?? this.latestPhysical,
      latestDiscipline:
      latestDiscipline ??
          this.latestDiscipline,
      latestTeamwork:
      latestTeamwork ??
          this.latestTeamwork,
      latestOverall:
      latestOverall ?? this.latestOverall,
      latestEvaluationCreatedAt:
      latestEvaluationCreatedAt ??
          this.latestEvaluationCreatedAt,
    );
  }
}

class PlayerInput {
  const PlayerInput({
    required this.code,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.status,
    required this.parentName,
    required this.parentPhone,
    this.groupId,
    this.groupName,
    this.schedule,
    this.relationship = 'Father',
    this.photo,
    this.medicalNotes,
  });

  final String code;
  final String name;
  final String birthDate;
  final String gender;
  final String status;

  /// Preferred relationship field used by the current backend.
  final int? groupId;

  /// Kept temporarily so older edit screens still compile.
  /// New create/update screens should use groupId.
  final String? groupName;
  final String? schedule;

  final String parentName;
  final String parentPhone;
  final String relationship;
  final String? photo;
  final String? medicalNotes;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json =
    <String, dynamic>{
      'player_code': code.trim(),
      'full_name': name.trim(),
      'birth_date': birthDate.trim(),
      'gender': gender,
      'status': status,
      'parent_name': parentName.trim(),
      'parent_phone': parentPhone.trim(),
      'relationship': relationship,
      'photo': _nullableTrim(photo),
      'medical_notes':
      _nullableTrim(medicalNotes),
    };

    if (groupId != null) {
      json['group_id'] = groupId;
    } else {
      final String? legacyGroupName =
      _nullableTrim(groupName);
      final String? legacySchedule =
      _nullableTrim(schedule);

      if (legacyGroupName != null) {
        json['group_name'] = legacyGroupName;
      }

      if (legacySchedule != null) {
        json['training_schedule'] =
            legacySchedule;
      }
    }

    return json;
  }
}

String? _nullableTrim(String? value) {
  if (value == null) {
    return null;
  }

  final String trimmed = value.trim();

  return trimmed.isEmpty ? null : trimmed;
}

String? _asString(dynamic value) {
  if (value == null) {
    return null;
  }

  final String result =
  value.toString().trim();

  return result.isEmpty ? null : result;
}

int? _asInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}
