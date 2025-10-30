class Location {
  final String id;
  final String location;
  final String contact_phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Location({
    required this.id,
    required this.location,
    required this.contact_phone,
    this.createdAt,
    this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id'],
      location: json['name'],
      contact_phone: json['contact_phone'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': location,
    'contact_phone': contact_phone,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
