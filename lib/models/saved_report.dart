class SavedReport {
  final int? id;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final String filePath;
  final String fileName;

  SavedReport({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.filePath,
    required this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'generated_at': generatedAt.toIso8601String(),
      'file_path': filePath,
      'file_name': fileName,
    };
  }

  factory SavedReport.fromMap(Map<String, dynamic> map) {
    return SavedReport(
      id: map['id'] as int?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      generatedAt: DateTime.parse(map['generated_at'] as String),
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
    );
  }

  SavedReport copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? generatedAt,
    String? filePath,
    String? fileName,
  }) {
    return SavedReport(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      generatedAt: generatedAt ?? this.generatedAt,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
    );
  }
}
