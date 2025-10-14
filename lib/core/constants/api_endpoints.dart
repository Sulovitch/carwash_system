// lib/core/constants/api_endpoints.dart
class ApiEndpoints {
  // Base
  static const String base = '/api';

  // Auth
  static const String signIn = '/signin.php';
  static const String signUp = '/signup.php';
  static const String logout = '/logout.php';

  // User
  static const String updateUserProfile = '/update_user_profile.php';
  static const String getUserProfile = '/get_user_profile.php';

  // Owner
  static const String updateOwnerProfile = '/update_owner_profile.php';

  // Car
  static const String cars = '/car.php';
  static const String getCars = '/get_cars.php';
  static const String addCar = '/car.php'; // POST
  static const String updateCar = '/car.php'; // PUT
  static const String deleteCar = '/car.php'; // DELETE

  // CarWash
  static const String carWashes = '/carwash.php';
  static const String fetchCarWashes = '/fetch_CarWashes.php';
  static const String updateCarWash = '/carwash.php';

  // Service
  static const String services = '/service.php';
  static const String fetchServices = '/fetch_services.php';
  static const String addService = '/service.php';
  static const String updateService = '/service.php';
  static const String deleteService = '/service.php';

  // Reservation
  static const String reservations = '/save_reservation.php';
  static const String fetchReservations = '/fetch_reservations.php';
  static const String fetchUserReservations = '/fetch_user_reservations.php';
  static const String updateReservationStatus =
      '/update_reservation_status.php';
  static const String cancelReservation = '/cancel_reservation.php';
  static const String restoreReservation = '/restore_reservation_status.php';

  // Receptionist
  static const String receptionists = '/receptionist.php';
  static const String fetchReceptionists = '/Fetch_Receptionists.php';
  static const String addReceptionist = '/receptionist.php';
  static const String updateReceptionist = '/receptionist.php';
  static const String deleteReceptionist = '/receptionist.php';

  // Transaction
  static const String transactions = '/Transaction.php';

  // Availability
  static const String checkAvailability = '/check_availability.php';
  static const String reserveSlot = '/reserve_slot.php';

  // Capacity
  static const String getDaySlots = '/get_day_slots.php';
  static const String toggleSlot = '/toggle_slot.php';
  static const String updateCapacity = '/update_capacity.php';
  static const String addTimeSlot = '/add_time_slot.php';
  static const String deleteSlot = '/delete_slot.php';

  // Dashboard
  static const String dashboardData = '/dashboard_data.php';

  // Notifications
  static const String sendNotification = '/send_notification.php';
  static const String getUserNotifications = '/get_user_notifications.php';
  static const String markNotificationRead = '/mark_notification_read.php';

  // Upload
  static const String uploadUrl = '/uploads/';
}
