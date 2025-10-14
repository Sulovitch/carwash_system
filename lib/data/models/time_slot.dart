class TimeSlot {
  final String id;
  final String time;
  final int capacity;
  final int bookedCount;
  final int appBookings;
  final int walkInBookings;
  final int phoneBookings;
  final bool isActive;

  TimeSlot({
    required this.id,
    required this.time,
    required this.capacity,
    required this.bookedCount,
    this.appBookings = 0,
    this.walkInBookings = 0,
    this.phoneBookings = 0,
    this.isActive = true,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'].toString(),
      time: json['time'] as String,
      capacity: int.tryParse(json['capacity'].toString()) ?? 0,
      bookedCount: int.tryParse(json['booked_count'].toString()) ?? 0,
      appBookings: int.tryParse(json['app_bookings'].toString()) ?? 0,
      walkInBookings: int.tryParse(json['walk_in_bookings'].toString()) ?? 0,
      phoneBookings: int.tryParse(json['phone_bookings'].toString()) ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  int get availableSpots => capacity - bookedCount;

  double get occupancyRate => capacity > 0 ? bookedCount / capacity : 0;
}
