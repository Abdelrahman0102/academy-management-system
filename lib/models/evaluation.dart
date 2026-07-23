// evaluation.dart
/// Immutable evaluation record for the Sports Academy Management System.
///
/// Mirrors the conventions used by `PlayerModel`: JSON keys are
/// snake_case, Dart fields are camelCase, and score/rating totals are
/// calculated by the backend — this model only carries them, it never
/// computes them.
class EvaluationModel {
  const EvaluationModel({
    required this.id,
    required this.playerId,
    this.coachId,
    this.sessionId,
    // Technical
    this.passing,
    this.dribbling,
    this.shooting,
    this.runningWithBall,
    this.ballControl,
    // Physical
    this.agilityFlexibility,
    this.strength,
    this.speed,
    this.coordination,
    // Tactical
    this.attack,
    this.defense,
    // Psychological
    this.decisionMaking,
    this.awareness,
    this.attentionFocus,
    // Personal
    this.determination,
    this.creativity,
    this.selfConfidence,
    this.leadership,
    this.cooperation,
    // Discipline
    this.emotionalStability,
    this.trainingAttendance,
    this.followingInstructions,
    this.uniformCommitment,
    this.behavior,
    // Pressure
    this.pressurePerformance,
    // Calculated (backend-authoritative)
    this.technicalTotal,
    this.physicalTotal,
    this.tacticalTotal,
    this.psychologicalTotal,
    this.personalTotal,
    this.disciplineTotal,
    this.pressureTotal,
    this.overallScore,
    this.overallPercentage,
    this.rating,
    // Notes
    this.notes,
    // Dates
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int playerId;
  final int? coachId;
  final int? sessionId;

  // Technical & Skills
  final int? passing;
  final int? dribbling;
  final int? shooting;
  final int? runningWithBall;
  final int? ballControl;

  // Physical
  final int? agilityFlexibility;
  final int? strength;
  final int? speed;
  final int? coordination;

  // Tactical
  final int? attack;
  final int? defense;

  // Psychological Performance
  final int? decisionMaking;
  final int? awareness;
  final int? attentionFocus;

  // Personal Traits
  final int? determination;
  final int? creativity;
  final int? selfConfidence;
  final int? leadership;
  final int? cooperation;

  // Discipline & Rules
  final int? emotionalStability;
  final int? trainingAttendance;
  final int? followingInstructions;
  final int? uniformCommitment;
  final int? behavior;

  // Performance Under Match Pressure
  final int? pressurePerformance;

  /// Calculated values returned by the API. Flutter never derives
  /// these itself — the backend remains the source of truth.
  final int? technicalTotal;
  final int? physicalTotal;
  final int? tacticalTotal;
  final int? psychologicalTotal;
  final int? personalTotal;
  final int? disciplineTotal;
  final int? pressureTotal;
  final int? overallScore;
  final double? overallPercentage;
  final String? rating;

  final String? notes;

  final String? createdAt;
  final String? updatedAt;

  factory EvaluationModel.fromJson(Map<String, dynamic> json) {
    return EvaluationModel(
      id: _asInt(json['id']) ?? 0,
      playerId: _asInt(json['player_id']) ?? 0,
      coachId: _asInt(json['coach_id']),
      sessionId: _asInt(json['session_id']),
      passing: _asInt(json['passing']),
      dribbling: _asInt(json['dribbling']),
      shooting: _asInt(json['shooting']),
      runningWithBall: _asInt(json['running_with_ball']),
      ballControl: _asInt(json['ball_control']),
      agilityFlexibility: _asInt(json['agility_flexibility']),
      strength: _asInt(json['strength']),
      speed: _asInt(json['speed']),
      coordination: _asInt(json['coordination']),
      attack: _asInt(json['attack']),
      defense: _asInt(json['defense']),
      decisionMaking: _asInt(json['decision_making']),
      awareness: _asInt(json['awareness']),
      attentionFocus: _asInt(json['attention_focus']),
      determination: _asInt(json['determination']),
      creativity: _asInt(json['creativity']),
      selfConfidence: _asInt(json['self_confidence']),
      leadership: _asInt(json['leadership']),
      cooperation: _asInt(json['cooperation']),
      emotionalStability: _asInt(json['emotional_stability']),
      trainingAttendance: _asInt(json['training_attendance']),
      followingInstructions: _asInt(json['following_instructions']),
      uniformCommitment: _asInt(json['uniform_commitment']),
      behavior: _asInt(json['behavior']),
      pressurePerformance: _asInt(json['pressure_performance']),
      technicalTotal: _asInt(json['technical_total']),
      physicalTotal: _asInt(json['physical_total']),
      tacticalTotal: _asInt(json['tactical_total']),
      psychologicalTotal: _asInt(json['psychological_total']),
      personalTotal: _asInt(json['personal_total']),
      disciplineTotal: _asInt(json['discipline_total']),
      pressureTotal: _asInt(json['pressure_total']),
      overallScore: _asInt(json['overall_score']),
      overallPercentage: _asDouble(json['overall_percentage']),
      rating: _asString(json['rating']),
      notes: _asString(json['notes']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
    );
  }

  /// Only raw, coach-entered fields are sent to the API. Calculated
  /// totals and the rating are backend-owned and intentionally
  /// omitted here.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'player_id': playerId,
      'coach_id': coachId,
      'session_id': sessionId,
      'passing': passing,
      'dribbling': dribbling,
      'shooting': shooting,
      'running_with_ball': runningWithBall,
      'ball_control': ballControl,
      'agility_flexibility': agilityFlexibility,
      'strength': strength,
      'speed': speed,
      'coordination': coordination,
      'attack': attack,
      'defense': defense,
      'decision_making': decisionMaking,
      'awareness': awareness,
      'attention_focus': attentionFocus,
      'determination': determination,
      'creativity': creativity,
      'self_confidence': selfConfidence,
      'leadership': leadership,
      'cooperation': cooperation,
      'emotional_stability': emotionalStability,
      'training_attendance': trainingAttendance,
      'following_instructions': followingInstructions,
      'uniform_commitment': uniformCommitment,
      'behavior': behavior,
      'pressure_performance': pressurePerformance,
      'notes': notes,
    };
  }

  EvaluationModel copyWith({
    int? id,
    int? playerId,
    int? coachId,
    int? sessionId,
    int? passing,
    int? dribbling,
    int? shooting,
    int? runningWithBall,
    int? ballControl,
    int? agilityFlexibility,
    int? strength,
    int? speed,
    int? coordination,
    int? attack,
    int? defense,
    int? decisionMaking,
    int? awareness,
    int? attentionFocus,
    int? determination,
    int? creativity,
    int? selfConfidence,
    int? leadership,
    int? cooperation,
    int? emotionalStability,
    int? trainingAttendance,
    int? followingInstructions,
    int? uniformCommitment,
    int? behavior,
    int? pressurePerformance,
    int? technicalTotal,
    int? physicalTotal,
    int? tacticalTotal,
    int? psychologicalTotal,
    int? personalTotal,
    int? disciplineTotal,
    int? pressureTotal,
    int? overallScore,
    double? overallPercentage,
    String? rating,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return EvaluationModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      coachId: coachId ?? this.coachId,
      sessionId: sessionId ?? this.sessionId,
      passing: passing ?? this.passing,
      dribbling: dribbling ?? this.dribbling,
      shooting: shooting ?? this.shooting,
      runningWithBall: runningWithBall ?? this.runningWithBall,
      ballControl: ballControl ?? this.ballControl,
      agilityFlexibility: agilityFlexibility ?? this.agilityFlexibility,
      strength: strength ?? this.strength,
      speed: speed ?? this.speed,
      coordination: coordination ?? this.coordination,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      decisionMaking: decisionMaking ?? this.decisionMaking,
      awareness: awareness ?? this.awareness,
      attentionFocus: attentionFocus ?? this.attentionFocus,
      determination: determination ?? this.determination,
      creativity: creativity ?? this.creativity,
      selfConfidence: selfConfidence ?? this.selfConfidence,
      leadership: leadership ?? this.leadership,
      cooperation: cooperation ?? this.cooperation,
      emotionalStability: emotionalStability ?? this.emotionalStability,
      trainingAttendance: trainingAttendance ?? this.trainingAttendance,
      followingInstructions:
      followingInstructions ?? this.followingInstructions,
      uniformCommitment: uniformCommitment ?? this.uniformCommitment,
      behavior: behavior ?? this.behavior,
      pressurePerformance: pressurePerformance ?? this.pressurePerformance,
      technicalTotal: technicalTotal ?? this.technicalTotal,
      physicalTotal: physicalTotal ?? this.physicalTotal,
      tacticalTotal: tacticalTotal ?? this.tacticalTotal,
      psychologicalTotal: psychologicalTotal ?? this.psychologicalTotal,
      personalTotal: personalTotal ?? this.personalTotal,
      disciplineTotal: disciplineTotal ?? this.disciplineTotal,
      pressureTotal: pressureTotal ?? this.pressureTotal,
      overallScore: overallScore ?? this.overallScore,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EvaluationModel &&
        other.id == id &&
        other.playerId == playerId &&
        other.coachId == coachId &&
        other.sessionId == sessionId &&
        other.passing == passing &&
        other.dribbling == dribbling &&
        other.shooting == shooting &&
        other.runningWithBall == runningWithBall &&
        other.ballControl == ballControl &&
        other.agilityFlexibility == agilityFlexibility &&
        other.strength == strength &&
        other.speed == speed &&
        other.coordination == coordination &&
        other.attack == attack &&
        other.defense == defense &&
        other.decisionMaking == decisionMaking &&
        other.awareness == awareness &&
        other.attentionFocus == attentionFocus &&
        other.determination == determination &&
        other.creativity == creativity &&
        other.selfConfidence == selfConfidence &&
        other.leadership == leadership &&
        other.cooperation == cooperation &&
        other.emotionalStability == emotionalStability &&
        other.trainingAttendance == trainingAttendance &&
        other.followingInstructions == followingInstructions &&
        other.uniformCommitment == uniformCommitment &&
        other.behavior == behavior &&
        other.pressurePerformance == pressurePerformance &&
        other.technicalTotal == technicalTotal &&
        other.physicalTotal == physicalTotal &&
        other.tacticalTotal == tacticalTotal &&
        other.psychologicalTotal == psychologicalTotal &&
        other.personalTotal == personalTotal &&
        other.disciplineTotal == disciplineTotal &&
        other.pressureTotal == pressureTotal &&
        other.overallScore == overallScore &&
        other.overallPercentage == overallPercentage &&
        other.rating == rating &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    playerId,
    coachId,
    sessionId,
    passing,
    dribbling,
    shooting,
    runningWithBall,
    ballControl,
    agilityFlexibility,
    strength,
    speed,
    coordination,
    attack,
    defense,
    decisionMaking,
    awareness,
    attentionFocus,
    determination,
    creativity,
    selfConfidence,
    leadership,
    cooperation,
    emotionalStability,
    trainingAttendance,
    followingInstructions,
    uniformCommitment,
    behavior,
    pressurePerformance,
    technicalTotal,
    physicalTotal,
    tacticalTotal,
    psychologicalTotal,
    personalTotal,
    disciplineTotal,
    pressureTotal,
    overallScore,
    overallPercentage,
    rating,
    notes,
    createdAt,
    updatedAt,
  ]);

  @override
  String toString() {
    return 'EvaluationModel(id: $id, playerId: $playerId, '
        'overallScore: $overallScore, overallPercentage: $overallPercentage, '
        'rating: $rating)';
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final String result = value.toString().trim();
  return result.isEmpty ? null : result;
}
