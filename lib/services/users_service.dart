import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final int userId;
  final String username;
  final String email;
  final String role;
  String reg_date;
  String last_login;
  final bool isActive;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    this.reg_date = " ",
    this.last_login = " ",
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: int.parse(json['user_id'].toString()),
      username: json['username'],
      email: json['email'],
      role: json['role'],
      // reg_date: json['reg_date'],
      // last_login: json['last_login'],
      isActive: json['is_active'] == '1' || json['is_active'] == 1,
    );
  }
}

class UserService {
  static const String baseUrl = "http://localhost/library_api/users_api.php";

  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load users");
    }
  }

  Future<bool> createUser(
    String username,
    String email,
    String password,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "role": role,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateUser(
    int userId,
    String username,
    String email,
    String role,
    // String reg_date,
    // String last_login,
    bool isActive,
  ) async {
    final response = await http.put(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "username": username,
        "email": email,
        "role": role,
        // "reg_date": reg_date,
        // "last_login": last_login,
        "is_active": isActive ? 1 : 0,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: "user_id=$userId",
    );
    return response.statusCode == 200;
  }
}
