class ApiConfig {
  // Base URL - غيره حسب السيرفر حقك
  static const String baseUrl = 'http://10.0.2.2/myapp/api';

  // Endpoints
  static String get carEndpoint => '$baseUrl/car.php';
  static String get carWashEndpoint => '$baseUrl/carwash.php';
  static String get authEndpoint => '$baseUrl/signin.php';
  static String get signupEndpoint => '$baseUrl/signup.php';
  static String get serviceEndpoint => '$baseUrl/service.php';
  static String get reservationEndpoint => '$baseUrl/save_reservation.php';
  static String get fetchReservationsEndpoint =>
      '$baseUrl/fetch_reservations.php';
  static String get fetchUserReservationsEndpoint =>
      '$baseUrl/fetch_user_reservations.php';
  static String get fetchServicesEndpoint => '$baseUrl/fetch_services.php';
  static String get fetchCarWashesEndpoint => '$baseUrl/fetch_CarWashes.php';
  static String get fetchReceptionistsEndpoint =>
      '$baseUrl/Fetch_Receptionists.php';
  static String get receptionistEndpoint => '$baseUrl/receptionist.php';
  static String get updateReservationStatusEndpoint =>
      '$baseUrl/update_reservation_status.php';
  static String get cancelReservationEndpoint =>
      '$baseUrl/cancel_reservation.php';
  static String get restoreReservationEndpoint =>
      '$baseUrl/restore_reservation_status.php';
  static String get updateOwnerProfileEndpoint =>
      '$baseUrl/update_owner_profile.php';
  static String get updateUserProfileEndpoint =>
      '$baseUrl/update_user_profile.php';
  static String get getCarsEndpoint => '$baseUrl/get_cars.php';
  static String get transactionEndpoint => '$baseUrl/Transaction.php';

  // Upload URL
  static String get uploadUrl => '$baseUrl/uploads/';

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
