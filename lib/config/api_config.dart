// API configuration for Flutter Web application
class ApiConfig {
  // Base URL for the backend API
  // For local development, use http://localhost
  // For production, update this URL accordingly
  static const String apiBaseUrl = 'http://localhost';

  // API endpoints
  static const String usersApi = '$apiBaseUrl/library_api/users_api.php';
  static const String booksApi = '$apiBaseUrl/library_api/books_api.php';
  static const String ordersApi = '$apiBaseUrl/library_api/orders_api.php';
  static const String customersApi =
      '$apiBaseUrl/library_api/customers_api.php';
  static const String reviewsApi = '$apiBaseUrl/library_api/reviews_api.php';
}
