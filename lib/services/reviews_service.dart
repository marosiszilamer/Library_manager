import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class Review {
  final int reviewId;
  final int bookId;
  final int? customerId;
  final String username;
  final int rating;
  final String? comment;
  final String reviewDate;

  Review({
    required this.reviewId,
    required this.bookId,
    this.customerId,
    required this.username,
    required this.rating,
    this.comment,
    required this.reviewDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: int.parse(json['review_id'].toString()),
      bookId: int.parse(json['book_id'].toString()),
      customerId: json['customer_id'] != null
          ? int.parse(json['customer_id'].toString())
          : null,
      username: json['username'] ?? 'Anonim',
      rating: int.parse(json['rating'].toString()),
      comment: json['comment'],
      reviewDate: json['review_date'] ?? '',
    );
  }
}

class ReviewService {
  static const String baseUrl = ApiConfig.reviewsApi;

  /// Get all reviews for a book
  Future<List<Review>> fetchReviewsByBookId(int bookId) async {
    final response = await http.get(Uri.parse('$baseUrl?book_id=$bookId'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to load reviews");
    }
  }

  /// Create a new review
  Future<int> createReview({
    required int bookId,
    required String username,
    required int rating,
    required String? comment,
  }) async {
    final body = jsonEncode({
      'action': 'create',
      'book_id': bookId,
      'username': username,
      'rating': rating,
      'comment': comment ?? '',
    });

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['review_id'] as int;
      } else {
        throw Exception(data['message'] ?? 'Failed to create review');
      }
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create review');
    }
  }
}
