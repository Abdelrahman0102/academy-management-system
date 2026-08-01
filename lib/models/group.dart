class TrainingGroupModel {
  const TrainingGroupModel({
    required this.id,
    required this.name,
    this.level,
    this.schedule,
    this.coachName,
    this.maxPlayers,
    this.playersCount,
    this.coachId,
    this.availablePlaces,
    this.isFull = false,
    this.hasStructuredSchedule = false,
    this.schedules = const <GroupScheduleModel>[],
    this.createdAt,
  });

  final int id;
  final String name;
  final String? level;
  final String? schedule;
  final String? coachName;
  final int? maxPlayers;
  final int? playersCount;
  final int? coachId;
  final int? availablePlaces;
  final bool isFull;
  final bool hasStructuredSchedule;
  final List<GroupScheduleModel> schedules;
  final String? createdAt;

  String get groupName => name;
  int get safePlayersCount => playersCount ?? 0;
  bool get hasCapacityLimit => maxPlayers != null && maxPlayers! > 0;

  double get capacityPercentage {
    if (!hasCapacityLimit) return 0.0;
    return (safePlayersCount / maxPlayers!)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  factory TrainingGroupModel.fromJson(Map<String, dynamic> json) {
    final List<GroupScheduleModel> parsedSchedules =
    _parseSchedules(json['schedules']);
    final int? parsedMaxPlayers = _asInt(json['max_players']);
    final int parsedPlayersCount = _asInt(json['players_count']) ?? 0;
    final int? parsedAvailablePlaces =
        _asInt(json['available_places']) ??
            (parsedMaxPlayers == null
                ? null
                : (parsedMaxPlayers - parsedPlayersCount) < 0
                ? 0
                : parsedMaxPlayers - parsedPlayersCount);
    final bool calculatedIsFull =
        parsedMaxPlayers != null && parsedPlayersCount >= parsedMaxPlayers;

    return TrainingGroupModel(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['group_name'] ?? json['name']) ?? '-',
      level: _asString(json['level']),
      schedule: _asString(json['schedule']),
      coachName: _asString(json['coach_name']),
      maxPlayers: parsedMaxPlayers,
      playersCount: parsedPlayersCount,
      coachId: _asInt(json['coach_id']),
      availablePlaces: parsedAvailablePlaces,
      isFull: _asBool(json['is_full']) ?? calculatedIsFull,
      hasStructuredSchedule:
      _asBool(json['has_structured_schedule']) ?? parsedSchedules.isNotEmpty,
      schedules: List<GroupScheduleModel>.unmodifiable(parsedSchedules),
      createdAt: _asString(json['created_at']),
    );
  }
}

class GroupScheduleModel {
  const GroupScheduleModel({
    this.id,
    this.groupId,
    required this.dayNumber,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final int? id;
  final int? groupId;
  final int dayNumber;
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  String get displayLabel => '$dayOfWeek $startTime–$endTime';

  factory GroupScheduleModel.fromJson(Map<String, dynamic> json) {
    final String? rawDay = _asString(json['day_of_week']);
    final int dayNumber =
        _asInt(json['day_number']) ?? _dayNumberFromName(rawDay) ?? 1;

    return GroupScheduleModel(
      id: _asInt(json['id']),
      groupId: _asInt(json['group_id']),
      dayNumber: dayNumber,
      dayOfWeek: rawDay ?? _dayNameFromNumber(dayNumber),
      startTime: _normalizeTime(json['start_time']) ?? '00:00',
      endTime: _normalizeTime(json['end_time']) ?? '00:00',
    );
  }
}

class GroupScheduleRequest {
  const GroupScheduleRequest({
    required this.dayNumber,
    required this.startTime,
    required this.endTime,
  });

  final int dayNumber;
  final String startTime;
  final String endTime;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'day_of_week': dayNumber,
    'start_time': startTime,
    'end_time': endTime,
  };
}

List<GroupScheduleModel> _parseSchedules(dynamic value) {
  if (value is! List) return const <GroupScheduleModel>[];

  final List<GroupScheduleModel> schedules = value
      .whereType<Map>()
      .map((Map item) => GroupScheduleModel.fromJson(
    Map<String, dynamic>.from(item),
  ))
      .toList(growable: false);

  schedules.sort((GroupScheduleModel a, GroupScheduleModel b) {
    final int day = a.dayNumber.compareTo(b.dayNumber);
    return day != 0 ? day : a.startTime.compareTo(b.startTime);
  });

  return schedules;
}

String? _normalizeTime(dynamic value) {
  final String? raw = _asString(value);
  if (raw == null) return null;

  final RegExpMatch? match =
  RegExp(r'^([01]\d|2[0-3]):([0-5]\d)').firstMatch(raw);
  return match == null ? raw : '${match.group(1)}:${match.group(2)}';
}

String _dayNameFromNumber(int value) {
  switch (value) {
    case 1:
      return 'Saturday';
    case 2:
      return 'Sunday';
    case 3:
      return 'Monday';
    case 4:
      return 'Tuesday';
    case 5:
      return 'Wednesday';
    case 6:
      return 'Thursday';
    case 7:
      return 'Friday';
    default:
      return 'Saturday';
  }
}

int? _dayNumberFromName(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'saturday':
      return 1;
    case 'sunday':
      return 2;
    case 'monday':
      return 3;
    case 'tuesday':
      return 4;
    case 'wednesday':
      return 5;
    case 'thursday':
      return 6;
    case 'friday':
      return 7;
    default:
      return null;
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

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;

  switch (value.toString().trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
      return true;
    case '0':
    case 'false':
    case 'no':
      return false;
    default:
      return null;
  }
}
