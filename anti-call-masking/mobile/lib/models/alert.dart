class Alert {
  final String id;
  final DateTime timestamp;
  final String bNumber;
  final List<String> aNumbers;
  final List<String> sourceIps;
  final int callCount;
  final int windowSeconds;
  final String severity;
  final String status;
  final String? assignedTo;
  final String? notes;

  Alert({
    required this.id,
    required this.timestamp,
    required this.bNumber,
    required this.aNumbers,
    required this.sourceIps,
    required this.callCount,
    required this.windowSeconds,
    required this.severity,
    required this.status,
    this.assignedTo,
    this.notes,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      bNumber: json['bNumber'] as String,
      aNumbers: List<String>.from(json['aNumbers'] ?? []),
      sourceIps: List<String>.from(json['sourceIps'] ?? []),
      callCount: json['callCount'] as int,
      windowSeconds: json['windowSeconds'] as int? ?? 5,
      severity: json['severity'] as String,
      status: json['status'] as String,
      assignedTo: json['assignedTo'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'bNumber': bNumber,
      'aNumbers': aNumbers,
      'sourceIps': sourceIps,
      'callCount': callCount,
      'windowSeconds': windowSeconds,
      'severity': severity,
      'status': status,
      'assignedTo': assignedTo,
      'notes': notes,
    };
  }

  Alert copyWith({
    String? id,
    DateTime? timestamp,
    String? bNumber,
    List<String>? aNumbers,
    List<String>? sourceIps,
    int? callCount,
    int? windowSeconds,
    String? severity,
    String? status,
    String? assignedTo,
    String? notes,
  }) {
    return Alert(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      bNumber: bNumber ?? this.bNumber,
      aNumbers: aNumbers ?? this.aNumbers,
      sourceIps: sourceIps ?? this.sourceIps,
      callCount: callCount ?? this.callCount,
      windowSeconds: windowSeconds ?? this.windowSeconds,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
    );
  }
}
