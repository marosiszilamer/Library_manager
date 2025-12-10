import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class Customer {
  final int customerId;
  final int userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String city;
  final String postalCode;
  final String? username;
  final String? email;

  Customer({
    required this.customerId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    required this.city,
    required this.postalCode,
    this.username,
    this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: int.parse(json['customer_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postal_code'] ?? '',
      username: json['username'],
      email: json['email'],
    );
  }
}

class CustomerService {
  static const String baseUrl = ApiConfig.customersApi;

  /// Get all customers
  Future<List<Customer>> fetchAllCustomers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to load customers");
    }
  }

  /// Get customer by customer_id
  Future<Customer> fetchCustomerById(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl?customer_id=$customerId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Customer.fromJson(data as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      throw Exception("Customer not found");
    } else {
      throw Exception("Failed to load customer");
    }
  }

  /// Get customers for a specific user_id
  Future<List<Customer>> fetchCustomersByUserId(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl?user_id=$userId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to load customer for user");
    }
  }

  /// Create a new customer
  Future<int> createCustomer({
    required int userId,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String city,
    required String postalCode,
  }) async {
    final body = jsonEncode({
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address': address,
      'city': city,
      'postal_code': postalCode,
    });

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['customer_id'] as int;
      } else {
        throw Exception(data['error'] ?? 'Failed to create customer');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to create customer');
    }
  }

  /// Update an existing customer
  Future<bool> updateCustomer({
    required int customerId,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String city,
    required String postalCode,
  }) async {
    final body = jsonEncode({
      'customer_id': customerId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address': address,
      'city': city,
      'postal_code': postalCode,
    });

    final response = await http.put(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update customer');
    }
  }

  /// Delete a customer
  Future<bool> deleteCustomer(int customerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl?customer_id=$customerId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to delete customer');
    }
  }
}
