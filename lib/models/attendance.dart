// attendance.dart
import 'package:equatable/equatable.dart';

/// {@template attendance_model}
/// Immutable model representing a single attendance record.
/// {@endtemplate}
class AttendanceModel extends Equatable {
  /// {@macro attendance_model}
  const AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.status,
    this.notes,
  });

  /// Unique identifier for the attendance record.
  final int id;

  /// The session ID this attendance belongs to.
  final int sessionId;

  /// The player ID this attendance is for.
  final int playerId;

  /// Attendance status: 'Present' or 'Excused'.
  final String status;

  /// Optional notes for the attendance record.
  final String? notes;

  /// Creates an [AttendanceModel] from a JSON map.
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      playerId: json['player_id'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }

  /// Converts this [AttendanceModel] to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'session_id': sessionId,
      'player_id': playerId,
      'status': status,
      'notes': notes,
    };
  }

  /// Creates a copy of this [AttendanceModel] with the given fields
  /// replaced with the new values.
  AttendanceModel copyWith({
    int? id,
    int? sessionId,
    int? playerId,
    String? status,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, sessionId, playerId, status, notes];
}
