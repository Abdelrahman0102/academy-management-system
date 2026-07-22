// group.dart
class TrainingGroupModel {
  const TrainingGroupModel({
    required this.id,
    required this.name,
    this.level,
    this.schedule,
    this.coachName,
    this.maxPlayers,
    this.playersCount,
  });

  final int id;
  final String name;
  final String? level;
  final String? schedule;
  final String? coachName;
  final int? maxPlayers;
  final int? playersCount;

  factory TrainingGroupModel.fromJson(Map<String, dynamic> json) {
    return TrainingGroupModel(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['group_name']) ?? '-',
      level: _asString(json['level']),
      schedule: _asString(json['schedule']),
      coachName: _asString(json['coach_name']),
      maxPlayers: _asInt(json['max_players']),
      playersCount: _asInt(json['players_count']),
    );
  }
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

