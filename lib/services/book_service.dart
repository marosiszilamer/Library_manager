import 'dart:convert';
import 'package:http/http.dart' as http;

class BookService {
  static const String baseUrl =
      "http://localhost/library_manager/books_api.php";

  // 📚 1. LEKÉRÉS (READ)
  static Future<List<dynamic>> getBooks() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load books");
    }
  }

  // ➕ 2. HOZZÁADÁS (CREATE)
  static Future<bool> addBook(Map<String, dynamic> book) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(book),
    );

    return response.statusCode == 200;
  }

  // ✏️ 3. MÓDOSÍTÁS (UPDATE)
  static Future<bool> updateBook(int bookId, Map<String, dynamic> book) async {
    final response = await http.put(
      Uri.parse("$baseUrl?book_id=$bookId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(book),
    );

    return response.statusCode == 200;
  }

  // ❌ 4. TÖRLÉS (DELETE)
  static Future<bool> deleteBook(int bookId) async {
    final response = await http.delete(Uri.parse("$baseUrl?book_id=$bookId"));

    return response.statusCode == 200;
  }
}
