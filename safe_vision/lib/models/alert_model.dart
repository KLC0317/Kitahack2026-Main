import 'package:flutter/material.dart';

class AlertModel {
  final String id;
  final String location;
  final String type;
  final String severity;
  final String details;
  final DateTime timestamp;
  final bool resolved;
  final String? detectedBy;        // NEW: Camera/Sensor that detected it
  final String? description;       // NEW: Detailed description
  final double? confidenceScore;   // NEW: AI confidence (0.0 to 1.0)
  final String? imageUrl;          // NEW: Screenshot/evidence image
  final List<String>? tags;        // NEW: Tags for categorization
  final String? assignedTo;        // NEW: Security personnel assigned
  final DateTime? resolvedAt;      // NEW: When it was resolved
  final String? resolutionNotes;   // NEW: How it was resolved
  final int? responseTime;         // NEW: Response time in seconds
  final String? floor;             // NEW: Floor information
  final String? block;             // NEW: Block information
  final Map<String, dynamic>? metadata; // NEW: Additional flexible data

  AlertModel({
    required this.id,
    required this.location,
    required this.type,
    required this.severity,
    required this.details,
    required this.timestamp,
    this.resolved = false,
    this.detectedBy,
    this.description,
    this.confidenceScore,
    this.imageUrl,
    this.tags,
    this.assignedTo,
    this.resolvedAt,
    this.resolutionNotes,
    this.responseTime,
    this.floor,
    this.block,
    this.metadata,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      location: map['location'] ?? '',
      type: map['type'] ?? '',
      severity: map['severity'] ?? '',
      details: map['details'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      resolved: map['resolved'] ?? false,
      detectedBy: map['detectedBy'],
      description: map['description'],
      confidenceScore: map['confidenceScore']?.toDouble(),
      imageUrl: map['imageUrl'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      assignedTo: map['assignedTo'],
      resolvedAt: map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
      resolutionNotes: map['resolutionNotes'],
      responseTime: map['responseTime'],
      floor: map['floor'],
      block: map['block'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'location': location,
      'type': type,
      'severity': severity,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'resolved': resolved,
      'detectedBy': detectedBy,
      'description': description,
      'confidenceScore': confidenceScore,
      'imageUrl': imageUrl,
      'tags': tags,
      'assignedTo': assignedTo,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'responseTime': responseTime,
      'floor': floor,
      'block': block,
      'metadata': metadata,
    };
  }

  // Helper method to get severity color
  Color getSeverityColor() {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return const Color(0xFFFF6B6B);
      case 'MEDIUM':
        return const Color(0xFFFF8E53);
      case 'LOW':
        return const Color(0xFF9CCC65);
      default:
        return Colors.grey;
    }
  }

  // Helper method to get type icon
  IconData getTypeIcon() {
    switch (type.toLowerCase()) {
      case 'unauthorized access':
        return Icons.lock_open;
      case 'suspicious behavior':
        return Icons.warning_amber_rounded;
      case 'equipment tampering':
        return Icons.build_circle;
      case 'fire detected':
        return Icons.local_fire_department;
      case 'intrusion':
        return Icons.person_off;
      case 'medical emergency':
        return Icons.medical_services;
      case 'vandalism':
        return Icons.report_problem;
      default:
        return Icons.notifications_active;
    }
  }

  // Helper method to format timestamp
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Helper method to get confidence level text
  String getConfidenceLevel() {
    if (confidenceScore == null) return 'Unknown';
    if (confidenceScore! >= 0.9) return 'Very High';
    if (confidenceScore! >= 0.75) return 'High';
    if (confidenceScore! >= 0.5) return 'Medium';
    return 'Low';
  }

  // Copy with method for easy updates
  AlertModel copyWith({
    String? id,
    String? location,
    String? type,
    String? severity,
    String? details,
    DateTime? timestamp,
    bool? resolved,
    String? detectedBy,
    String? description,
    double? confidenceScore,
    String? imageUrl,
    List<String>? tags,
    String? assignedTo,
    DateTime? resolvedAt,
    String? resolutionNotes,
    int? responseTime,
    String? floor,
    String? block,
    Map<String, dynamic>? metadata,
  }) {
    return AlertModel(
      id: id ?? this.id,
      location: location ?? this.location,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      resolved: resolved ?? this.resolved,
      detectedBy: detectedBy ?? this.detectedBy,
      description: description ?? this.description,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      assignedTo: assignedTo ?? this.assignedTo,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      responseTime: responseTime ?? this.responseTime,
      floor: floor ?? this.floor,
      block: block ?? this.block,
      metadata: metadata ?? this.metadata,
    );
  }
}
