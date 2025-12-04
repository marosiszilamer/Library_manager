import 'package:flutter/material.dart';
import '../services/book_service.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  List<dynamic> books = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    final data = await BookService.getBooks();
    setState(() => books = data);
  }

  Future<void> addBook() async {
    await BookService.addBook({
      "title": titleController.text,
      "author_id": 1,
      "category_id": 1,
      "price": 20.5,
      "stock": 10,
      "isbn": "1234567890",
      "publisher": "Default",
      "published_year": 2020,
      "description": "New book",
      "cover_image": "",
    });
    titleController.clear();
    await loadBooks();
  }

  Future<void> deleteBook(int id) async {
    await BookService.deleteBook(id);
    await loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📚 Books Manager")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Book title",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(onPressed: addBook, child: const Text("Add Book")),
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final id = int.tryParse(book['book_id']?.toString() ?? '') ?? 0;
                return ListTile(
                  title: Text(book['title']),
                  isThreeLine: true,
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Publisher: ${book['publisher'] ?? ''}"),
                      Text("ISBN: ${book['isbn'] ?? ''}"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteBook(id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
