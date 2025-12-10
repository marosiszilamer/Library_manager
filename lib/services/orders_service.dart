import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class Order {
  final int orderId;
  final int customerId;
  final String orderDate;
  final String status;
  final double totalAmount;
  final String shippingAddress;
  final String paymentMethod;
  final List<OrderItem>? items;

  Order({
    required this.orderId,
    required this.customerId,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: int.parse(json['order_id'].toString()),
      customerId: int.parse(json['customer_id'].toString()),
      orderDate: json['order_date'] ?? '',
      status: json['status'] ?? 'függőben',
      totalAmount: double.parse(json['total_amount'].toString()),
      shippingAddress: json['shipping_address'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderItem {
  final int orderItemId;
  final int bookId;
  final int quantity;
  final double price;
  final String? bookTitle;
  final String? authorName;
  final String? coverImage;

  OrderItem({
    required this.orderItemId,
    required this.bookId,
    required this.quantity,
    required this.price,
    this.bookTitle,
    this.authorName,
    this.coverImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: int.parse(json['order_item_id'].toString()),
      bookId: int.parse(json['book_id'].toString()),
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['price'].toString()),
      bookTitle: json['title'],
      authorName: json['author_name'],
      coverImage: json['cover_image'],
    );
  }
}

class OrderService {
  static const String baseUrl = ApiConfig.ordersApi;

  /// Get all orders (admin only)
  Future<List<Order>> fetchAllOrders() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to load orders");
    }
  }

  /// Get orders for a specific customer
  Future<List<Order>> fetchOrdersByCustomerId(int customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl?customer_id=$customerId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to load customer orders");
    }
  }

  /// Get orders for a specific user by username
  Future<List<Order>> fetchOrdersByUsername(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl?username=${Uri.encodeComponent(username)}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception("Failed to load orders for user");
    }
  }

  /// Get a single order by order_id
  Future<Order> fetchOrderById(int orderId) async {
    final response = await http.get(Uri.parse('$baseUrl?order_id=$orderId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Order.fromJson(data as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      throw Exception("Order not found");
    } else {
      throw Exception("Failed to load order");
    }
  }

  /// Place a new order
  /// Returns the order_id if successful
  Future<int> placeOrder({
    required int customerId,
    required String shippingAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = jsonEncode({
      'customer_id': customerId,
      'shipping_address': shippingAddress,
      'payment_method': paymentMethod,
      'items': items,
    });

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['order_id'] as int;
      } else {
        throw Exception(data['error'] ?? 'Failed to place order');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to place order');
    }
  }
}
