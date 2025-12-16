import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'LogInPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Book> _books = [];
  final List<Book> _allBooks = [];
  bool _loading = false;
  bool _hasSearched = false;

  // Adjust this to your server's base address
  static const String _apiBase = 'http://10.227.70.4:80/library_api';

  @override
  void initState() {
    super.initState();
    _loadAllBooks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllBooks() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$_apiBase/books_api.php');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final list = (decoded as List?) ?? [];
        _allBooks
          ..clear()
          ..addAll(list.map((e) => Book.fromJson(e)).whereType<Book>());
        _books
          ..clear()
          ..addAll(_allBooks);
      } else {
        _fallbackSample('');
      }
    } catch (e) {
      _fallbackSample('');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LogInPage()),
      (route) => false,
    );
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    if (q.isEmpty) {
      // Show all books when search is empty
      setState(() {
        _books
          ..clear()
          ..addAll(_allBooks);
        _loading = false;
      });
      return;
    }

    try {
      // Try server search first
      final uri = Uri.parse(
        '$_apiBase/books_api.php?q=${Uri.encodeQueryComponent(q)}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        final list = (decoded as List?) ?? [];
        setState(() {
          _books
            ..clear()
            ..addAll(list.map((e) => Book.fromJson(e)).whereType<Book>());
        });
      } else {
        // Fallback to local filtering
        _localSearch(q);
      }
    } catch (e) {
      // Fallback to local filtering
      _localSearch(q);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _localSearch(String q) {
    final query = q.toLowerCase();
    setState(() {
      _books
        ..clear()
        ..addAll(
          _allBooks.where(
            (b) =>
                b.title.toLowerCase().contains(query) ||
                b.author.toLowerCase().contains(query),
          ),
        );
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _books
        ..clear()
        ..addAll(_allBooks);
      _hasSearched = false;
    });
  }

  void _fallbackSample(String q) {
    // Simple local sample results when the backend is unreachable
    final samples = [
      Book(id: 1, title: '1984', author: 'George Orwell', price: 9.99),
      Book(
        id: 2,
        title: 'A kis herceg',
        author: 'Antoine de Saint-Exupéry',
        price: 7.49,
      ),
      Book(
        id: 3,
        title: 'Egri csillagok',
        author: 'Gárdonyi Géza',
        price: 8.25,
      ),
    ];
    _books
      ..clear()
      ..addAll(
        q.isEmpty
            ? samples
            : samples.where(
                (b) =>
                    b.title.toLowerCase().contains(q.toLowerCase()) ||
                    b.author.toLowerCase().contains(q.toLowerCase()),
              ),
      );
  }

  Future<void> _buy(Book book) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$_apiBase/orders_api.php');
      final resp = await http.post(uri, body: {'book_id': book.id.toString()});
      if (resp.statusCode == 200) {
        _showSnack('Vásárlás sikeres: ${book.title}');
      } else {
        _showSnack('Vásárlás sikertelen (${resp.statusCode})');
      }
    } catch (e) {
      _showSnack('Vásárlás hiba: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Könyvek'),
        actions: [
          IconButton(
            tooltip: 'Kijelentkezés',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          onChanged: (_) {
                            // Real-time search as user types
                            if (_searchCtrl.text.isEmpty) {
                              _clearSearch();
                            }
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Keresés könyv cím vagy szerző alapján...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _loading ? null : _search,
                        icon: const Icon(Icons.search),
                        label: const Text('Keresés'),
                      ),
                    ],
                  ),
                  if (_hasSearched && _books.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${_books.length} találat',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else
              const SizedBox(height: 2),
            Expanded(
              child: _books.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _hasSearched ? Icons.search_off : Icons.book,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasSearched
                                ? 'Nincs találat a keresésre'
                                : 'Írj be egy keresési kifejezést',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_hasSearched) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _clearSearch,
                              child: const Text('Összes könyv megjelenítése'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _books.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final b = _books[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: const Icon(Icons.book_outlined),
                            ),
                            title: Text(
                              b.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.author,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${b.price.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: FilledButton.icon(
                              onPressed: () => _buy(b),
                              icon: const Icon(Icons.shopping_cart, size: 18),
                              label: const Text('Vásárlás'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Book {
  final int id;
  final String title;
  final String author;
  final double price;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
  });

  factory Book.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final id = int.tryParse(json['id']?.toString() ?? '') ?? 0;
      final title = (json['title'] ?? json['name'] ?? '').toString();
      final author = (json['author'] ?? '').toString();
      final price = double.tryParse(json['price']?.toString() ?? '') ?? 0.0;
      return Book(id: id, title: title, author: author, price: price);
    }
    return Book(id: 0, title: json.toString(), author: '', price: 0.0);
  }
}
