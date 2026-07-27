class ParentAccountRequestModel {
  const ParentAccountRequestModel({
    required this.userId,
    required this.parentId,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.requestedAt,
    required this.players,
    this.address,
  });

  final int userId;
  final int parentId;
  final String fullName;
  final String phone;
  final String? address;
  final String status;
  final String requestedAt;
  final List<ParentRequestPlayerModel> players;

  factory ParentAccountRequestModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final dynamic rawPlayers = json['players'];

    return ParentAccountRequestModel(
      userId: _asInt(json['user_id']),
      parentId: _asInt(json['parent_id']),
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: _asString(json['address']),
      status: json['status']?.toString() ?? '',
      requestedAt:
      json['requested_at']?.toString() ?? '',
      players: rawPlayers is List
          ? rawPlayers
          .whereType<Map>()
          .map(
            (Map item) =>
            ParentRequestPlayerModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
      )
          .toList(growable: false)
          : const <ParentRequestPlayerModel>[],
    );
  }
}

class ParentRequestPlayerModel {
  const ParentRequestPlayerModel({
    required this.id,
    required this.playerCode,
    required this.fullName,
    required this.relationship,
    required this.isPrimary,
  });

  final int id;
  final String playerCode;
  final String fullName;
  final String relationship;
  final bool isPrimary;

  factory ParentRequestPlayerModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ParentRequestPlayerModel(
      id: _asInt(json['id']),
      playerCode:
      json['player_code']?.toString() ?? '',
      fullName:
      json['full_name']?.toString() ?? '',
      relationship:
      json['relationship']?.toString() ?? '',
      isPrimary: _asBool(json['is_primary']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final String result = value.toString().trim();
  return result.isEmpty ? null : result;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString() == '1';
}
