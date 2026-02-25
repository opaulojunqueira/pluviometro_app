class RainRecord {
  final int? id;
  final DateTime date;
  final double millimeters;
  final String? observation;
  final DateTime createdAt;
  final DateTime updatedAt;

  RainRecord({
    this.id,
    required this.date,
    required this.millimeters,
    this.observation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'millimeters': millimeters,
      'observation': observation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RainRecord.fromMap(Map<String, dynamic> map) {
    return RainRecord(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      millimeters: (map['millimeters'] as num).toDouble(),
      observation: map['observation'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  RainRecord copyWith({
    int? id,
    DateTime? date,
    double? millimeters,
    String? observation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RainRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      millimeters: millimeters ?? this.millimeters,
      observation: observation ?? this.observation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RainRecord(id: $id, date: $date, millimeters: $millimeters, observation: $observation)';
  }
}
