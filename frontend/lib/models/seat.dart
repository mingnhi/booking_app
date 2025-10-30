class Seat {
  final String id;
  final String tripId;
  final int seatNumber;
  final String statusSeat; // Sử dụng status_seat thay vì isAvailable
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Seat({
    required this.id,
    required this.tripId,
    required this.seatNumber,
    required this.statusSeat,
    this.createdAt,
    this.updatedAt,
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['_id'],
      tripId: json['trip_id'],
      seatNumber: json['seat_number'],
      statusSeat: json['status_seat'] ?? 'UNAVAILABLE', // Giá trị mặc định nếu null
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'trip_id': tripId,
    'seat_number': seatNumber,
    'status_seat': statusSeat, // Gửi status_seat về backend
  };
}