import 'package:flutter/material.dart';

class SchoolLocation {
  final String id;
  final String name;
  final Offset position2D;
  final IconData icon;
  final Color color;
  final List<Offset> boundaries;
  final String floor;
  final String block;
  final String type;
  final Offset alertMarkerOffset;
  
  // NEW VARIABLES
  final int? capacity;              // Room capacity
  final List<String>? cameras;      // Camera IDs monitoring this location
  final List<String>? sensors;      // Sensor IDs in this location
  final bool? restricted;           // Is this a restricted area?
  final String? accessLevel;        // Required access level
  final List<String>? connectedRooms; // Adjacent rooms/locations
  final double? area;               // Area in square meters
  final String? department;         // Department responsible
  final Map<String, dynamic>? equipment; // Equipment in this location
  final bool? hasEmergencyExit;    // Emergency exit available
  final String? emergencyContact;   // Emergency contact for this area
  final int? alertCount;            // Historical alert count
  final DateTime? lastInspection;   // Last safety inspection
  final double? riskScore;          // AI-calculated risk score (0.0 to 1.0)

  SchoolLocation({
    required this.id,
    required this.name,
    required this.position2D,
    required this.icon,
    required this.color,
    required this.boundaries,
    required this.floor,
    required this.block,
    required this.type,
    this.alertMarkerOffset = Offset.zero,
    this.capacity,
    this.cameras,
    this.sensors,
    this.restricted,
    this.accessLevel,
    this.connectedRooms,
    this.area,
    this.department,
    this.equipment,
    this.hasEmergencyExit,
    this.emergencyContact,
    this.alertCount,
    this.lastInspection,
    this.riskScore,
  });

  Offset get center {
    if (boundaries.isEmpty) return position2D;
    
    double sumX = 0;
    double sumY = 0;
    for (var point in boundaries) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / boundaries.length, sumY / boundaries.length);
  }
  
  Offset get alertPosition {
    return center + alertMarkerOffset;
  }

  // Helper method to get risk level
  String getRiskLevel() {
    if (riskScore == null) return 'Unknown';
    if (riskScore! >= 0.7) return 'High Risk';
    if (riskScore! >= 0.4) return 'Medium Risk';
    return 'Low Risk';
  }

  // Helper method to get risk color
  Color getRiskColor() {
    if (riskScore == null) return Colors.grey;
    if (riskScore! >= 0.7) return const Color(0xFFFF6B6B);
    if (riskScore! >= 0.4) return const Color(0xFFFF8E53);
    return const Color(0xFF9CCC65);
  }

  // Helper method to check if location is monitored
  bool get isMonitored {
    return (cameras != null && cameras!.isNotEmpty) || 
           (sensors != null && sensors!.isNotEmpty);
  }

  // Helper method to get monitoring devices count
  int get monitoringDevicesCount {
    int count = 0;
    if (cameras != null) count += cameras!.length;
    if (sensors != null) count += sensors!.length;
    return count;
  }

  // Copy with method
  SchoolLocation copyWith({
    String? id,
    String? name,
    Offset? position2D,
    IconData? icon,
    Color? color,
    List<Offset>? boundaries,
    String? floor,
    String? block,
    String? type,
    Offset? alertMarkerOffset,
    int? capacity,
    List<String>? cameras,
    List<String>? sensors,
    bool? restricted,
    String? accessLevel,
    List<String>? connectedRooms,
    double? area,
    String? department,
    Map<String, dynamic>? equipment,
    bool? hasEmergencyExit,
    String? emergencyContact,
    int? alertCount,
    DateTime? lastInspection,
    double? riskScore,
  }) {
    return SchoolLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      position2D: position2D ?? this.position2D,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      boundaries: boundaries ?? this.boundaries,
      floor: floor ?? this.floor,
      block: block ?? this.block,
      type: type ?? this.type,
      alertMarkerOffset: alertMarkerOffset ?? this.alertMarkerOffset,
      capacity: capacity ?? this.capacity,
      cameras: cameras ?? this.cameras,
      sensors: sensors ?? this.sensors,
      restricted: restricted ?? this.restricted,
      accessLevel: accessLevel ?? this.accessLevel,
      connectedRooms: connectedRooms ?? this.connectedRooms,
      area: area ?? this.area,
      department: department ?? this.department,
      equipment: equipment ?? this.equipment,
      hasEmergencyExit: hasEmergencyExit ?? this.hasEmergencyExit,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      alertCount: alertCount ?? this.alertCount,
      lastInspection: lastInspection ?? this.lastInspection,
      riskScore: riskScore ?? this.riskScore,
    );
  }
}

class SchoolMapData {
  // ============================================
  // IMAGE DIMENSIONS
  // ============================================
  static const double IMAGE_WIDTH = 1145.0;
  static const double IMAGE_HEIGHT = 1269.0;

  // ============================================
  // HELPER FUNCTIONS FOR EASY POSITIONING
  // ============================================
  
  /// Convert percentage (0.0 to 1.0) to pixel coordinates
  static Offset percentToPixel(double xPercent, double yPercent) {
    return Offset(
      IMAGE_WIDTH * xPercent,
      IMAGE_HEIGHT * yPercent,
    );
  }

  // ============================================
  // PRESET POSITIONS (Easy to use)
  // ============================================
  
  // Top row (20% from top)
  static Offset get topLeft => percentToPixel(0.25, 0.20);
  static Offset get topCenter => percentToPixel(0.50, 0.20);
  static Offset get topRight => percentToPixel(0.75, 0.20);
  
  // Middle row (50% from top)
  static Offset get middleLeft => percentToPixel(0.25, 0.50);
   static Offset get middleCenter => percentToPixel(0.50, 0.50);
  static Offset get middleRight => percentToPixel(0.75, 0.50);
  
  // Bottom row (80% from top)
  static Offset get bottomLeft => percentToPixel(0.25, 0.80);
  static Offset get bottomCenter => percentToPixel(0.50, 0.80);
  static Offset get bottomRight => percentToPixel(0.75, 0.80);

  // ============================================
  // GROUND FLOOR (All Blocks Combined)
  // Changed from 'static final' to 'static get' for hot reload
  // ============================================
  static List<SchoolLocation> get groundFloor => [
    SchoolLocation(
      id: 'g_main_gate',
      name: 'Main Gate',
      position2D: topCenter,
      icon: Icons.door_front_door,
      color: Colors.grey,
      type: 'entrance',
      floor: 'Ground',
      block: 'A',
      boundaries: [topCenter],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_class_1',
      name: 'Class 1A',
      position2D: topLeft,
      icon: Icons.school,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Ground',
      block: 'A',
      boundaries: [topLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_class_2',
      name: 'Class 2A',
      position2D: middleLeft,
      icon: Icons.class_,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Ground',
      block: 'A',
      boundaries: [middleLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_class_3',
      name: 'Class 3A',
      position2D: topRight,
      icon: Icons.school,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Ground',
      block: 'A',
      boundaries: [topRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_class_4',
      name: 'Class 4A',
      position2D: middleRight,
      icon: Icons.class_,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Ground',
      block: 'A',
      boundaries: [middleRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_library',
      name: 'Library',
      position2D: bottomRight,
      icon: Icons.library_books,
      color: Colors.purple,
      type: 'facility',
      floor: 'Ground',
      block: 'A',
      boundaries: [bottomRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_canteen',
      name: 'Canteen',
      position2D: bottomLeft,
      icon: Icons.restaurant,
      color: Colors.orange,
      type: 'facility',
      floor: 'Ground',
      block: 'A',
      boundaries: [bottomLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_playground',
      name: 'Playground',
      position2D: percentToPixel(0.50, 0.90),
      icon: Icons.sports_soccer,
      color: Colors.green,
      type: 'outdoor',
      floor: 'Ground',
      block: 'A',
      boundaries: [percentToPixel(0.50, 0.90)],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_toilet',
      name: 'Restroom',
      position2D: middleCenter,
      icon: Icons.wc,
      color: Colors.cyan,
      type: 'facility',
      floor: 'Ground',
      block: 'A',
      boundaries: [middleCenter],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_office',
      name: 'Admin Office',
      position2D: percentToPixel(0.50, 0.15),
      icon: Icons.business,
      color: Colors.red.shade700,
      type: 'facility',
      floor: 'Ground',
      block: 'A',
      boundaries: [percentToPixel(0.50, 0.15)],
      alertMarkerOffset: Offset.zero,
    ),

    // Block B Ground Floor
    SchoolLocation(
      id: 'g_lab_1',
      name: 'Physics Lab',
      position2D: percentToPixel(0.25, 0.30),
      icon: Icons.science,
      color: Colors.teal,
      type: 'lab',
      floor: 'Ground',
      block: 'B',
      boundaries: [percentToPixel(0.25, 0.30)],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_lab_2',
      name: 'Chemistry Lab',
      position2D: percentToPixel(0.75, 0.30),
      icon: Icons.biotech,
      color: Colors.teal,
      type: 'lab',
      floor: 'Ground',
      block: 'B',
      boundaries: [percentToPixel(0.75, 0.30)],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_computer_lab',
      name: 'Computer Lab',
      position2D: percentToPixel(0.25, 0.55),
      icon: Icons.computer,
      color: Colors.indigo,
      type: 'lab',
      floor: 'Ground',
      block: 'B',
      boundaries: [percentToPixel(0.25, 0.55)],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_staff_room',
      name: 'Staff Room',
      position2D: percentToPixel(0.75, 0.55),
      icon: Icons.groups,
      color: Colors.brown,
      type: 'facility',
      floor: 'Ground',
      block: 'B',
      boundaries: [percentToPixel(0.75, 0.55)],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'g_cafeteria',
      name: 'Cafeteria',
      position2D: percentToPixel(0.50, 0.80),
      icon: Icons.local_cafe,
      color: Colors.orange.shade700,
      type: 'facility',
      floor: 'Ground',
      block: 'B',
      boundaries: [percentToPixel(0.50, 0.80)],
      alertMarkerOffset: const Offset(180, -380),
    ),
  ];

  // ============================================
  // FIRST FLOOR
  // Changed from 'static final' to 'static get' for hot reload
  // ============================================
  static List<SchoolLocation> get firstFloor => [
    SchoolLocation(
      id: 'auditorium_1',
      name: 'Auditorium 1',
      position2D: percentToPixel(0.50, 0.90),
      icon: Icons.stairs,
      color: Colors.grey,
      type: 'stairs',
      floor: 'First',
      block: 'A',
      boundaries: [percentToPixel(0.50, 0.90)],
      alertMarkerOffset: const Offset(50, -30),
    ),

    SchoolLocation(
      id: 'f1_class_1',
      name: 'Class 1B',
      position2D: topLeft,
      icon: Icons.school,
      color: Colors.blue,
      type: 'classroom',
      floor: 'First',
      block: 'B',
      boundaries: [topLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f1_class_2',
      name: 'Class 2B',
      position2D: middleLeft,
      icon: Icons.class_,
      color: Colors.blue,
      type: 'classroom',
      floor: 'First',
      block: 'B',
      boundaries: [middleLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f1_class_3',
      name: 'Class 3B',
      position2D: topRight,
      icon: Icons.school,
      color: Colors.blue,
      type: 'classroom',
      floor: 'First',
      block: 'B',
      boundaries: [topRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f1_class_4',
      name: 'Class 4B',
      position2D: middleRight,
      icon: Icons.class_,
      color: Colors.blue,
      type: 'classroom',
      floor: 'First',
      block: 'B',
      boundaries: [middleRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f1_art_room',
      name: 'Art Room',
      position2D: bottomLeft,
      icon: Icons.palette,
      color: Colors.pink,
      type: 'special',
      floor: 'First',
      block: 'B',
      boundaries: [bottomLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f1_music_room',
      name: 'Music Room',
      position2D: bottomRight,
      icon: Icons.music_note,
      color: Colors.deepPurple,
      type: 'special',
      floor: 'First',
      block: 'B',
      boundaries: [bottomRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f1_study_hall',
      name: 'Study Hall',
      position2D: percentToPixel(0.50, 0.92),
      icon: Icons.menu_book,
      color: Colors.amber.shade800,
      type: 'facility',
      floor: 'First',
      block: 'B',
      boundaries: [percentToPixel(0.50, 0.92)],
      alertMarkerOffset: Offset.zero,
    ),
  ];

  // ============================================
  // SECOND FLOOR
  // Changed from 'static final' to 'static get' for hot reload
  // ============================================
  static List<SchoolLocation> get secondFloor => [
    SchoolLocation(
      id: 'f2_stairs',
      name: 'Staircase',
      position2D: percentToPixel(0.50, 0.12),
      icon: Icons.stairs,
      color: Colors.grey,
      type: 'stairs',
      floor: 'Second',
      block: 'C',
      boundaries: [percentToPixel(0.50, 0.12)],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f2_class_1',
      name: 'Class 5A',
      position2D: topLeft,
      icon: Icons.school,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Second',
      block: 'C',
      boundaries: [topLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f2_class_2',
      name: 'Class 6A',
      position2D: middleLeft,
      icon: Icons.class_,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Second',
      block: 'C',
      boundaries: [middleLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f2_class_3',
      name: 'Class 7A',
      position2D: topRight,
      icon: Icons.school,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Second',
      block: 'C',
      boundaries: [topRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f2_class_4',
      name: 'Class 8A',
      position2D: middleRight,
      icon: Icons.class_,
      color: Colors.blue,
      type: 'classroom',
      floor: 'Second',
      block: 'C',
      boundaries: [middleRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f2_conference',
      name: 'Conference Room',
      position2D: bottomLeft,
      icon: Icons.meeting_room,
      color: Colors.brown,
      type: 'facility',
      floor: 'Second',
      block: 'C',
      boundaries: [bottomLeft],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f2_auditorium',
      name:'Auditorium',
      position2D: bottomRight,
      icon: Icons.theater_comedy,
      color: Colors.purple,
      type: 'facility',
      floor: 'Second',
      block: 'C',
      boundaries: [bottomRight],
      alertMarkerOffset: Offset.zero,
    ),

    SchoolLocation(
      id: 'f2_storage',
      name: 'Storage Room',
      position2D: percentToPixel(0.50, 0.92),
      icon: Icons.inventory,
      color: Colors.grey,
      type: 'facility',
      floor: 'Second',
      block: 'C',
      boundaries: [percentToPixel(0.50, 0.92)],
      alertMarkerOffset: Offset.zero,
    ),
  ];

  // ============================================
  // HELPER METHODS
  // ============================================

  static List<SchoolLocation> getLocationsByFloor(String floor) {
    switch (floor) {
      case 'Ground':
        return groundFloor;
      case 'First':
        return firstFloor;
      case 'Second':
        return secondFloor;
      default:
        return groundFloor;
    }
  }

  static List<SchoolLocation> getLocations(String block, String floor) {
    // For backward compatibility
    return getLocationsByFloor(floor);
  }

  static List<String> getAvailableFloors(String block) {
    // For backward compatibility
    return ['Ground', 'First', 'Second'];
  }

  static List<String> getAllFloors() {
    return ['Ground', 'First', 'Second'];
  }

  static SchoolLocation? getLocationByName(String name, String block, String floor) {
    final locations = getLocationsByFloor(floor);
    
    // Normalize the search name
    final searchName = name.trim().toLowerCase();
    
    try {
      final location = locations.firstWhere(
        (loc) {
          final locName = loc.name.trim().toLowerCase();
          
          // Exact match
          if (locName == searchName) {
            return true;
          }
          
          // Contains match
          if (locName.contains(searchName) || searchName.contains(locName)) {
            return true;
          }
          
          return false;
        },
      );
      return location;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // QUICK REFERENCE GUIDE
  // ============================================
  /*
  
  ✅ NOW SUPPORTS HOT RELOAD! ✅
  
  Changed from 'static final' to 'static get' for:
  - groundFloor
  - firstFloor
  - secondFloor
  - All preset positions (topLeft, topCenter, etc.)
  
  POSITION PRESETS:
  ┌────────────────────────────────────────┐
  │  topLeft      topCenter     topRight   │
  │  (25%, 20%)   (50%, 20%)   (75%, 20%)  │
  │                                        │
  │  middleLeft   middleCenter middleRight │
  │  (25%, 50%)   (50%, 50%)   (75%, 50%)  │
  │                                        │
  │  bottomLeft   bottomCenter bottomRight │
  │  (25%, 80%)   (50%, 80%)   (75%, 80%)  │
  └────────────────────────────────────────┘

  USAGE EXAMPLES:

  1. Using presets:
     position2D: SchoolMapData.topLeft,

  2. Using percentages:
     position2D: SchoolMapData.percentToPixel(0.30, 0.40),
     // 30% from left, 40% from top

  3. Using exact pixels:
     position2D: const Offset(500, 600),

  4. Fine-tuning with offset (NOW HOT RELOAD WORKS!):
     position2D: SchoolMapData.topLeft,
     alertMarkerOffset: const Offset(20, -10),
     // Move 20px right, 10px up
     // Just press 'r' to see changes!

  OFFSET GUIDE:
  - Offset(x, y)
  - Positive x = RIGHT, Negative x = LEFT
  - Positive y = DOWN, Negative y = UP
  
  Examples:
  - Offset(50, 0)    → Move 50px right
  - Offset(-50, 0)   → Move 50px left
  - Offset(0, -50)   → Move 50px up
  - Offset(0, 50)    → Move 50px down
  - Offset(30, -20)  → Move 30px right, 20px up

  FLOOR STRUCTURE:
  - Ground Floor: All blocks combined (A & B)
  - First Floor: Block B classrooms and special rooms
  - Second Floor: Block C senior classes and facilities

  */
}


