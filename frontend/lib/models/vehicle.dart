class Vehicle {
  final String id;
  final String licensePlate;
  final String description;

  Vehicle({
    required this.id,
    required this.licensePlate,
    required this.description,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'],
      licensePlate: json['license_plate'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'license_plate': licensePlate,
    'description': description,
  };
}
