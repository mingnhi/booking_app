class Ticket {
  final String id;
  final String user_id;
  final String userFullName; // Thêm
  final String userPhoneNumber; // Thêm
  final String trip_id;
  final String tripDepartureLocation; // Thêm
  final String tripArrivalLocation; // Thêm
  final double tripPrice; // Thêm
  final String seat_id;
  final int seatNumber; // Thêm
  final String ticket_status;
  final DateTime booked_at;
  final DateTime? updated_at;

  Ticket({
    required this.id,
    required this.user_id,
    required this.userFullName,
    required this.userPhoneNumber,
    required this.trip_id,
    required this.tripDepartureLocation,
    required this.tripArrivalLocation,
    required this.tripPrice,
    required this.seat_id,
    required this.seatNumber,
    required this.ticket_status,
    required this.booked_at,
    this.updated_at,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['_id']?.toString() ?? '',
      user_id: json['user_id'] is String
          ? json['user_id']?.toString() ?? ''
          : json['user_id']?['_id']?.toString() ?? '',
      userFullName: json['user_id'] is String
          ? ''
          : json['user_id']?['full_name']?.toString() ?? '',
      userPhoneNumber: json['user_id'] is String
          ? ''
          : json['user_id']?['phone_number']?.toString() ?? '',
      trip_id: json['trip_id'] is String
          ? json['trip_id']?.toString() ?? ''
          : json['trip_id']?['_id']?.toString() ?? '',
      tripDepartureLocation: json['trip_id'] is String
          ? ''
          : json['trip_id']?['departure_location']?.toString() ?? '',
      tripArrivalLocation: json['trip_id'] is String
          ? ''
          : json['trip_id']?['arrival_location']?.toString() ?? '',
      tripPrice: json['trip_id'] is String
          ? 0.0
          : (json['trip_id']?['price'] as num?)?.toDouble() ?? 0.0,
      seat_id: json['seat_id'] is String
          ? json['seat_id']?.toString() ?? ''
          : json['seat_id']?['_id']?.toString() ?? '',
      seatNumber: json['seat_id'] is String
          ? 0
          : (json['seat_id']?['seat_number'] as num?)?.toInt() ?? 0,
      ticket_status: json['ticket_status']?.toString() ?? '',
      booked_at: DateTime.parse(json['booked_at']?.toString() ?? DateTime.now().toIso8601String()),
      updated_at: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': user_id,
    'trip_id': trip_id,
    'seat_id': seat_id,
    'ticket_status': ticket_status,
    'booked_at': booked_at.toIso8601String(),
    'updated_at': updated_at?.toIso8601String(),
  };
}