class DashboardData {
  final int todayBookings;
  final int activeBookings;
  final int completedBookings;
  final double todayRevenue;
  final int availableSpots;
  final int totalCapacity;
  final Map<String, int> bookingSources;
  final List<RecentBooking> recentBookings;
  final List<TimeSlot> criticalSlots;

  DashboardData({
    required this.todayBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.todayRevenue,
    required this.availableSpots,
    required this.totalCapacity,
    required this.bookingSources,
    required this.recentBookings,
    required this.criticalSlots,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      todayBookings: int.tryParse(json['today_bookings'].toString()) ?? 0,
      activeBookings: int.tryParse(json['active_bookings'].toString()) ?? 0,
      completedBookings:
          int.tryParse(json['completed_bookings'].toString()) ?? 0,
      todayRevenue: double.tryParse(json['today_revenue'].toString()) ?? 0.0,
      availableSpots: int.tryParse(json['available_spots'].toString()) ?? 0,
      totalCapacity: int.tryParse(json['total_capacity'].toString()) ?? 0,
      bookingSources: Map<String, int>.from(json['booking_sources'] ?? {}),
      recentBookings: (json['recent_bookings'] as List<dynamic>?)
              ?.map((e) => RecentBooking.fromJson(e))
              .toList() ??
          [],
      criticalSlots: (json['critical_slots'] as List<dynamic>?)
              ?.map((e) => TimeSlot.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RecentBooking {
  final String id;
  final String customerName;
  final String serviceName;
  final String time;
  final String status;
  final String source;

  RecentBooking({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.time,
    required this.status,
    required this.source,
  });

  factory RecentBooking.fromJson(Map<String, dynamic> json) {
    return RecentBooking(
      id: json['id'].toString(),
      customerName: json['customer_name'] as String,
      serviceName: json['service_name'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      source: json['source'] as String,
    );
  }
}
