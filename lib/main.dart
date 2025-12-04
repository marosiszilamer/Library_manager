import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login / Register',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF4A2C2A)),
      home: const AuthPage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  List<dynamic> orders = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);
    try {
      // Load user info
      final uResp = await http.get(
        Uri.parse('http://localhost/library_api/users_api.php'),
      );
      if (uResp.statusCode == 200) {
        final List<dynamic> list = json.decode(uResp.body) as List<dynamic>;
        final found = list.cast<Map<String, dynamic>>().firstWhere(
          (u) => (u['username'] ?? '').toString() == widget.username,
          orElse: () => {},
        );
        if (found.isNotEmpty) user = found;
      }

      // Load orders for this user
      final ordersUri = Uri.parse(
        'http://localhost/library_api/orders_api.php?username=${Uri.encodeComponent(widget.username)}',
      );
      final oResp = await http.get(ordersUri);
      if (oResp.statusCode == 200) {
        final data = json.decode(oResp.body);
        if (data is List) orders = data;
      }
    } catch (e) {
      debugPrint('Failed to load profile/orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hiba a profil betöltése közben: $e')),
      );
    }
    setState(() => loading = false);
  }

  Widget _buildUserInfo() {
    if (user == null) return const Text('Felhasználó adatai nem elérhetők');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Felhasználónév: ${user!['username'] ?? ''}'),
        const SizedBox(height: 6),
        Text('Email: ${user!['email'] ?? ''}'),
        const SizedBox(height: 6),
        Text('Regisztráció ideje: ${user!['registration_date'] ?? ''}'),
        const SizedBox(height: 6),
        Text('Szerepkör: ${user!['role'] ?? ''}'),
      ],
    );
  }

  Widget _buildOrders() {
    if (orders.isEmpty) return const Text('Nincs korábbi rendelésed.');
    return Column(
      children: orders.map((o) {
        final items = (o['items'] as List<dynamic>?) ?? [];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rendelés #${o['order_id'] ?? ''}'),
                    Text(o['created_at'] ?? ''),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: items.map<Widget>((it) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          it['cover_image'] != null &&
                              (it['cover_image'] as String).isNotEmpty
                          ? SizedBox(
                              width: 48,
                              child: buildCoverWidget(
                                it['cover_image'],
                                width: 48,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.book),
                      title: Text(it['title'] ?? ''),
                      subtitle: Text(
                        '${it['author_name'] ?? ''} • ${it['quantity'] ?? 0} db',
                      ),
                      trailing: Text('${it['unit_price'] ?? 0} Ft'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Végösszeg: ${o['total_amount'] ?? 0} Ft',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF4A2C2A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6),
                      ],
                    ),
                    child: _buildUserInfo(),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Rendeléseim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildOrders(),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A2C2A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Újratöltés'),
                  ),
                ],
              ),
      ),
    );
  }
}

// Helper cover image
Widget buildCoverWidget(
  String? path, {
  double? width,
  double? height,
  BoxFit? fit,
}) {
  const placeholder = Icon(
    Icons.book,
    size: 64,
    color: Color.fromARGB(255, 158, 158, 158),
  );

  Widget image;
  if (path != null && path.isNotEmpty) {
    if (path.startsWith('http')) {
      image = Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, error, stack) {
          debugPrint('Image load error: $error');
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.broken_image, size: 48, color: Colors.grey),
              SizedBox(height: 6),
              Text(
                'Nem tölthető',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      );
    } else {
      image = Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, error, stack) {
          debugPrint('Asset image error: $error');
          return placeholder;
        },
      );
    }
  } else {
    image = placeholder;
  }

  return ClipRRect(
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(8),
      topRight: Radius.circular(8),
    ),
    child: SizedBox(width: width, height: height, child: image),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showRegister = false;
  bool loggedIn = false;
  bool isAdmin = false;
  String userEmail = '';

  final loginPasswordController = TextEditingController();
  final loginUsernameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerUsernameController = TextEditingController();
  final registerConfirmController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  bool _loginObscure = true;
  bool showBooks = false;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load books from backend API on start
    _loadBooks();
  }

  List<Map<String, String>> books = [];
  List<String> categories = ['Minden'];
  String selectedCategory = 'Minden';

  /// Load books from `books_api.php` and map fields to the UI structure.
  Future<void> _loadBooks() async {
    try {
      final uri = Uri.parse('http://localhost/library_api/books_api.php');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body) as List<dynamic>;
        final mapped = data.map<Map<String, String>>((e) {
          final map = (e as Map<String, dynamic>);
          final priceNum =
              double.tryParse((map['price'] ?? '0').toString()) ?? 0.0;
          final authorName =
              map['author_name']?.toString() ?? map['author']?.toString() ?? '';
          final authorPlaceholder = authorName.isNotEmpty
              ? authorName
              : 'Szerző ${map['author_id'] ?? ''}';
          return {
            'book_id': map['book_id']?.toString() ?? '',
            'title': map['title']?.toString() ?? '',
            // Provide both 'author' and 'author_name' keys so UI can use either
            'author': authorPlaceholder,
            'author_name': authorName,
            'description': map['description']?.toString() ?? '',
            'publisher': map['publisher']?.toString() ?? '',
            'isbn': map['isbn']?.toString() ?? '',
            'pages': map['published_year']?.toString() ?? '',
            'language': map['language']?.toString() ?? 'magyar',
            'image':
                map['cover_image']?.toString() ??
                map['image']?.toString() ??
                '',
            'price': priceNum.toInt().toString(),
            // Map category and stock from API (category_name provided by books_api)
            'category':
                map['category_name']?.toString() ??
                map['category']?.toString() ??
                '',
            'stock': (map['stock'] ?? '').toString(),
          };
        }).toList();

        // build category list from returned books (safe fallback to 'Minden')
        final catSet = <String>{'Minden'};
        for (final m in mapped) {
          final c = (m['category'] ?? '').toString();
          if (c.isNotEmpty) catSet.add(c);
        }
        setState(() {
          books = mapped;
          categories = catSet.toList();
          // keep current selection if still available
          if (!categories.contains(selectedCategory))
            selectedCategory = 'Minden';
        });
      } else {
        debugPrint('Books API returned ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to load books: $e');
    }
  }

  // Kosár allapot és függvények
  List<Map<String, dynamic>> cart = [];

  // Kedvencek állapot és függvények
  List<Map<String, String>> favorites = [];

  bool isFavorite(Map<String, String> book) {
    return favorites.any(
      (b) => b['title'] == book['title'] && b['author'] == book['author'],
    );
  }

  void toggleFavorite(Map<String, String> book) {
    setState(() {
      if (isFavorite(book)) {
        favorites.removeWhere(
          (b) => b['title'] == book['title'] && b['author'] == book['author'],
        );
      } else {
        favorites.add(book);
      }
    });
  }

  bool isInCart(Map<String, String> book) {
    return cart.any(
      (b) =>
          b['title'] == book['title'] &&
          b['author'] == book['author'] &&
          (b['quantity'] as int) > 0,
    );
  }

  void addToCart(Map<String, dynamic> book, [int quantity = 1]) {
    setState(() {
      final existingIndex = cart.indexWhere(
        (b) => b['title'] == book['title'] && b['author'] == book['author'],
      );
      if (existingIndex != -1) {
        cart[existingIndex]['quantity'] =
            (cart[existingIndex]['quantity'] as int) + quantity;
      } else {
        cart.add({...book, 'quantity': quantity});
      }
    });
  }

  void removeFromCart(Map<String, dynamic> book) {
    setState(() {
      final existingIndex = cart.indexWhere(
        (b) => b['title'] == book['title'] && b['author'] == book['author'],
      );
      if (existingIndex != -1) {
        final currentQuantity = cart[existingIndex]['quantity'] as int;
        if (currentQuantity > 1) {
          cart[existingIndex]['quantity'] = currentQuantity - 1;
        } else {
          cart.removeAt(existingIndex);
        }
      }
    });
  }

  int getCartQuantity() {
    return cart.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  @override
  void dispose() {
    loginUsernameController.dispose();
    loginPasswordController.dispose();
    searchController.dispose();
    registerUsernameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmController.dispose();
    super.dispose();
  }

  void _login() {
    _performLogin();
  }

  Future<void> _performLogin() async {
    final valid = _loginFormKey.currentState?.validate() ?? false;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek töltsd ki a mezőket helyesen.')),
      );
      return;
    }

    final username = loginUsernameController.text.trim();
    final password = loginPasswordController.text;

    try {
      // Fetch the users list from the users_api and validate locally against the
      // provided `password_hash` field. This is OK for local/dev testing with
      // the static JSON dataset you shared. For production, validate on server.
      final uri = Uri.parse('http://localhost/library_api/users_api.php');
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final List<dynamic> list = json.decode(resp.body) as List<dynamic>;
        final users = list.cast<Map<String, dynamic>>();
        final user = users.firstWhere(
          (u) => (u['username'] ?? '').toString() == username,
          orElse: () => {},
        );

        if (user.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nincs ilyen felhasználó.')),
          );
        } else {
          final stored = (user['password_hash'] ?? '').toString();
          // NOTE: comparing plain input to stored value — this matches your
          // current dataset (e.g. password = "hash123"). In real apps use
          // secure hashing and server-side verification.
          if (password == stored) {
            setState(() {
              userEmail = username;
              loggedIn = true;
              showBooks = true;
              isAdmin =
                  (user['role'] ?? '').toString().contains('admin') ||
                  username.contains('admin');
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sikeres bejelentkezés.')),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Helytelen jelszó.')));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba a szerverrel: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hálózati hiba: $e')));
    }
  }

  void _logout() {
    setState(() {
      loggedIn = false;
      userEmail = '';
      isAdmin = false;
      cart.clear();
      favorites.clear();
    });
  }

  void _register() {
    _performRegister();
  }

  Future<void> _performRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    final username = registerUsernameController.text.trim();
    final email = registerEmailController.text.trim();
    final password = registerPasswordController.text;
    final confirm = registerConfirmController.text;
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A megadott jelszavak nem egyeznek.')),
      );
      return;
    }

    try {
      final uri = Uri.parse('http://localhost/library_api/users_api.php');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'create',
          'username': username,
          'email': email,
          'password': password,
          'role': 'customer',
        }),
      );

      if (resp.statusCode == 200) {
        Map<String, dynamic>? data;
        try {
          data = json.decode(resp.body) as Map<String, dynamic>?;
        } catch (_) {
          data = null;
        }

        final bool created =
            (data != null && data['success'] == true) ||
            (data != null && data['user_id'] != null) ||
            (resp.body.trim().isNotEmpty && data == null);

        if (created) {
          setState(() {
            userEmail = username;
            loggedIn = true;
            showBooks = true;
            isAdmin =
                (data != null && (data['role'] ?? '') == 'admin') ||
                username.contains('admin');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sikeres regisztráció és bejelentkezés.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (data != null && data['message'] != null)
                    ? data['message']
                    : 'Regisztráció sikertelen.',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba a szerverrel: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hálózati hiba: $e')));
    }
  }

  Future<Map<String, String>?> _showAddBookDialog() async {
    final titleC = TextEditingController();
    final authorC = TextEditingController();
    final imageC = TextEditingController();
    final priceC = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Új könyv hozzáadása'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleC,
              decoration: const InputDecoration(hintText: 'Cím'),
            ),
            TextField(
              controller: authorC,
              decoration: const InputDecoration(hintText: 'Szerző'),
            ),
            TextField(
              controller: imageC,
              decoration: const InputDecoration(
                hintText: 'Borító kép (URL, opcionális)',
              ),
            ),
            TextField(
              controller: priceC,
              decoration: const InputDecoration(hintText: 'Ár (Ft, pl. 2790)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () {
              final title = titleC.text.trim();
              final author = authorC.text.trim();
              if (title.isEmpty || author.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cím és szerző megadása kötelező'),
                  ),
                );
                return;
              }
              final map = <String, String>{
                'title': title,
                'author': author,
                'price': priceC.text.trim(),
              };
              if (imageC.text.trim().isNotEmpty) {
                map['image'] = imageC.text.trim();
              }
              Navigator.of(ctx).pop(map);
            },
            child: const Text('Hozzáad'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topBarHeight = showBooks ? 120.0 : 50.0;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Image.network(
                'https://i.etsystatic.com/11810216/r/il/9ad808/3025384484/il_1588xN.3025384484_6jy5.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Color.fromRGBO(0, 0, 0, 0.25)),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topBarHeight,
            child: Container(
              color: const Color(0xFF4A2C2A),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/librarymanager_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Center(
                        child: Text(
                          'Library',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (loggedIn && showBooks) ...[
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            hintText: 'Keresés könyv címe vagy szerző',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 8,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category filter dropdown
                    SizedBox(
                      width: 180,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedCategory,
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(
                                        c,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                selectedCategory = v ?? 'Minden';
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutPage(
                                  cart: cart,
                                  onAdd: addToCart,
                                  onRemove: removeFromCart,
                                  onOrderPlaced: () {
                                    setState(() {
                                      cart.clear();
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        if (cart.isNotEmpty)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${getCartQuantity()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => FavoritesDialog(
                            favorites: favorites,
                            onRemove: toggleFavorite,
                            onOpen: (book) {
                              // Navigate to book detail when a favorite is tapped
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookDetailPage(
                                    book: book,
                                    addToCart: addToCart,
                                    inCart: isInCart(book),
                                    loggedIn: loggedIn,
                                    username: userEmail,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    if (isAdmin)
                      ElevatedButton(
                        onPressed: () async {
                          final newBook = await _showAddBookDialog();
                          if (newBook != null) {
                            setState(() => books.add(newBook));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B3D38),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Új könyv'),
                      ),
                    const SizedBox(width: 8),
                    // Profile button
                    IconButton(
                      icon: const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (!loggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Jelentkezz be a profil megtekintéséhez.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(username: userEmail),
                          ),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B3D38),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kijelentkezés'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned.fill(
            top: topBarHeight,
            child: Center(
              child: loggedIn
                  ? (showBooks ? _buildBooksPage() : _buildAuthBoxes())
                  : _buildAuthBoxes(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthBoxes() {
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Visibility(
            visible: !showRegister,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D0),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Bejelentkezés', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 12),
                  Form(
                    key: _loginFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: loginUsernameController,
                          decoration: const InputDecoration(
                            hintText: 'Felhasználónév',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a felhasználóneved.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: loginPasswordController,
                          decoration: InputDecoration(
                            hintText: 'Jelszó',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _loginObscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _loginObscure = !_loginObscure,
                              ),
                            ),
                          ),
                          obscureText: _loginObscure,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Kérlek add meg a jelszót.';
                            }
                            if (v.length < 6) {
                              return 'A jelszónak legalább 6 karakter hosszúnak kell lennie.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A2C2A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Bejelentkezés'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF4A2C2A),
                    ),
                    child: const Text('Elfelejtette a jelszavát?'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Új felhasználó?'),
                      TextButton(
                        onPressed: () => setState(() => showRegister = true),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A2C2A),
                        ),
                        child: const Text('Regisztráció'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Visibility(
            visible: showRegister,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D0),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Regisztráció', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 12),
                  Form(
                    key: _registerFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: registerUsernameController,
                          decoration: const InputDecoration(
                            hintText: 'Felhasználónév',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a felhasználóneved.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: registerEmailController,
                          decoration: const InputDecoration(
                            hintText: 'Email cím',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg az email címed.';
                            }
                            if (!v.contains('@')) {
                              return 'Érvényes email címet adj meg.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: registerPasswordController,
                          decoration: const InputDecoration(
                            hintText: 'Jelszó',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Kérlek add meg a jelszót.';
                            }
                            if (v.length < 6) {
                              return 'A jelszónak legalább 6 karakter hosszúnak kell lennie.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: registerConfirmController,
                          decoration: const InputDecoration(
                            hintText: 'Jelszó Megerősítése',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Kérlek erősítsd meg a jelszót.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A2C2A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Regisztrálás'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Már van felhasználód?'),
                      TextButton(
                        onPressed: () => setState(() => showRegister = false),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A2C2A),
                        ),
                        child: const Text('Jelentkezz be!'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksPage() {
    final query = searchController.text.toLowerCase();
    final filtered = books.where((b) {
      final t = b['title']!.toLowerCase();
      final a = b['author']!.toLowerCase();
      final matchesText = t.contains(query) || a.contains(query);
      final cat = (b['category'] ?? '').toString();
      final matchesCategory =
          (selectedCategory == 'Minden' || selectedCategory.isEmpty)
          ? true
          : (cat == selectedCategory);
      return matchesText && matchesCategory;
    }).toList();
    return Container(
      width: 1000,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.25), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Könyvek',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: filtered.isEmpty
                  ? const Center(child: Text('Nincs találat'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final b = filtered[index];
                        return InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookDetailPage(
                                book: b,
                                addToCart: addToCart,
                                inCart: isInCart(b),
                                loggedIn: loggedIn,
                                username: userEmail,
                              ),
                            ),
                          ),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: buildCoverWidget(
                                        b['image'],
                                        width: double.infinity,
                                        height: 140,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            b['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            b['author_name'] ??
                                                b['author'] ??
                                                '',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Category and stock
                                          Row(
                                            children: [
                                              if ((b['category'] ?? '')
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8.0,
                                                      ),
                                                  child: Text(
                                                    b['category']!,
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              if ((b['stock'] ?? '').isNotEmpty)
                                                Text(
                                                  'Készlet: ${b['stock']}',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (b['price'] != null)
                                            Text(
                                              '${b['price']} Ft',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF4A2C2A),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Add to cart button positioned at the bottom of the card
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: isInCart(b)
                                          ? null
                                          : () {
                                              addToCart(b);
                                              setState(() {});
                                            },
                                      icon: const Icon(Icons.add_shopping_cart),
                                      label: Text(
                                        isInCart(b)
                                            ? 'Már a kosárban'
                                            : 'Kosárba',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isInCart(b)
                                            ? Colors.grey
                                            : const Color(0xFF4A2C2A),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      isFavorite(b)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite(b)
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () => toggleFavorite(b),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookDetailPage extends StatefulWidget {
  final Map<String, String> book;
  final void Function(Map<String, String> book) addToCart;
  final bool inCart;
  final bool loggedIn;
  final String username;

  const BookDetailPage({
    super.key,
    required this.book,
    required this.addToCart,
    this.inCart = false,
    this.loggedIn = false,
    this.username = '',
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  List<Map<String, dynamic>> reviews = [];
  int selectedRating = 5;
  final commentController = TextEditingController();
  bool loadingReviews = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    final bookId = widget.book['book_id'] ?? '';
    if (bookId.isEmpty) return;
    setState(() => loadingReviews = true);
    try {
      final uri = Uri.parse(
        'http://localhost/library_api/reviews_api.php?book_id=${Uri.encodeComponent(bookId)}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body) as List<dynamic>;
        reviews = data.map((e) => (e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load reviews: $e');
    }
    setState(() => loadingReviews = false);
  }

  double _avgRating() {
    if (reviews.isEmpty) return 0.0;
    final sum = reviews.fold<int>(0, (s, r) => s + (r['rating'] as int));
    return sum / reviews.length;
  }

  Future<void> _submitReview() async {
    if (!widget.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kérlek jelentkezz be a vélemény beküldéséhez.'),
        ),
      );
      return;
    }
    final bookId = widget.book['book_id'] ?? '';
    if (bookId.isEmpty) return;
    final uri = Uri.parse('http://localhost/library_api/reviews_api.php');
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'create',
          'book_id': bookId,
          'username': widget.username,
          'rating': selectedRating,
          'comment': commentController.text.trim(),
        }),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>?;
        if (data != null && data['success'] == true) {
          commentController.clear();
          await _fetchReviews();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Vélemény mentve.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hiba: ${data?['message'] ?? resp.body}')),
          );
        }
      } else {
        // Try to show server response body (may contain error message)
        String msg = 'Szerver hiba: ${resp.statusCode}';
        try {
          final body = json.decode(resp.body);
          if (body is Map && body['message'] != null)
            msg = 'Hiba: ${body['message']}';
          else
            msg = resp.body.toString();
        } catch (_) {
          // ignore JSON parse error
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hálózati hiba: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return Scaffold(
      appBar: AppBar(
        title: Text(book['title'] ?? 'Könyv'),
        backgroundColor: const Color(0xFF4A2C2A),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 900,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Container(
                          height: 360,
                          width: 240,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: buildCoverWidget(
                            book['image'],
                            width: 240,
                            height: 360,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          book['author_name'] ?? book['author'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (book['price'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 8),
                              child: Text(
                                '${book['price']} Ft',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF4A2C2A),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Category and stock on detail page
                          Row(
                            children: [
                              if ((book['category'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.category, size: 16),
                                      const SizedBox(width: 6),
                                      Text(book['category'] ?? ''),
                                    ],
                                  ),
                                ),
                              if ((book['stock'] ?? '').isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.storage, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Készlet: ${book['stock']}'),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            book['description'] ?? 'Nincs leírás',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          // Publisher and ISBN (show if present)
                          if ((book['publisher'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                bottom: 6.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.business, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Kiadó: ${book['publisher']}'),
                                ],
                              ),
                            ),
                          ],
                          if ((book['isbn'] ?? '').toString().isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 0.0,
                                bottom: 6.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.confirmation_number,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('ISBN: ${book['isbn']}'),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (book['pages'] != null) ...[
                                const Icon(Icons.menu_book, size: 16),
                                const SizedBox(width: 6),
                                Text('${book['pages']} kiadasú'),
                                const SizedBox(width: 18),
                              ],
                              if (book['language'] != null) ...[
                                const Icon(Icons.language, size: 16),
                                const SizedBox(width: 6),
                                Text(book['language']!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Reviews summary
                          Row(
                            children: [
                              const Text(
                                'Értékelés: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  final avg = _avgRating();
                                  return Icon(
                                    Icons.star,
                                    size: 18,
                                    color: (i < avg.round())
                                        ? Colors.amber
                                        : Colors.grey[300],
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                reviews.isEmpty
                                    ? 'Nincs értékelés'
                                    : '${_avgRating().toStringAsFixed(1)} (${reviews.length})',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Reviews list
                          loadingReviews
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                                  children: reviews
                                      .map(
                                        (r) => ListTile(
                                          title: Row(
                                            children: [
                                              Text(r['username'] ?? 'Anon'),
                                              const SizedBox(width: 8),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color:
                                                        (i <
                                                            (r['rating']
                                                                as int))
                                                        ? Colors.amber
                                                        : Colors.grey[300],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Text(r['comment'] ?? ''),
                                          trailing: Text(r['created_at'] ?? ''),
                                        ),
                                      )
                                      .toList(),
                                ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          // Submit form
                          widget.loggedIn
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Írd meg a véleményed'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: List.generate(5, (i) {
                                        final idx = i + 1;
                                        return IconButton(
                                          icon: Icon(
                                            idx <= selectedRating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: idx <= selectedRating
                                                ? Colors.amber
                                                : Colors.grey,
                                          ),
                                          onPressed: () => setState(
                                            () => selectedRating = idx,
                                          ),
                                        );
                                      }),
                                    ),
                                    TextField(
                                      controller: commentController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: 'Vélemény (opcionális)',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _submitReview,
                                      child: const Text('Küldés'),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Jelentkezz be a vélemény küldéséhez.',
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(widget.inCart ? 'Már a kosárban' : 'Kosárba'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.inCart
                ? Colors.grey
                : const Color(0xFF4A2C2A),
            foregroundColor: Colors.white,
          ),
          onPressed: widget.inCart
              ? null
              : () {
                  widget.addToCart(widget.book);
                  Navigator.pop(context);
                },
        ),
      ),
    );
  }
}

class CartDialog extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final void Function(Map<String, dynamic> book) onAdd;
  final void Function(Map<String, dynamic> book) onRemove;

  const CartDialog({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
  });

  int getTotal() {
    int total = 0;
    for (final book in cart) {
      final price = int.tryParse(book['price'] ?? '0') ?? 0;
      final quantity = book['quantity'] as int;
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kosár tartalma'),
      content: SizedBox(
        width: 330,
        child: cart.isEmpty
            ? const Text('A kosár üres.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...cart.map(
                    (book) => ListTile(
                      title: Text(book['title'] ?? ''),
                      subtitle: Text(
                        book['author_name'] ?? book['author'] ?? '',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              onRemove(book);
                              Navigator.of(context).pop();
                            },
                          ),
                          Text('${book['quantity']}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              onAdd(book);
                              Navigator.of(context).pop();
                            },
                          ),
                          const SizedBox(width: 8),
                          if (book['price'] != null)
                            Text(
                              '${(int.tryParse(book['price'] ?? '0') ?? 0) * (book['quantity'] as int)} Ft',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Végösszeg: ${getTotal()} Ft',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bezár'),
        ),
      ],
    );
  }
}

class FavoritesDialog extends StatelessWidget {
  final List<Map<String, String>> favorites;
  final void Function(Map<String, String> book) onRemove;
  final void Function(Map<String, String> book)? onOpen;

  const FavoritesDialog({
    super.key,
    required this.favorites,
    required this.onRemove,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kedvencek'),
      content: SizedBox(
        width: 330,
        child: favorites.isEmpty
            ? const Text('Nincs kedvenc könyv.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...favorites.map(
                    (book) => ListTile(
                      title: Text(book['title'] ?? ''),
                      subtitle: Text(
                        book['author_name'] ?? book['author'] ?? '',
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (onOpen != null) onOpen!(book);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          onRemove(book);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bezár'),
        ),
      ],
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final void Function(Map<String, dynamic> book) onAdd;
  final void Function(Map<String, dynamic> book) onRemove;
  final void Function() onOrderPlaced;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.onOrderPlaced,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final countyController = TextEditingController();
  final cityController = TextEditingController();
  final houseNumberController = TextEditingController();
  final postalCodeController = TextEditingController();
  // Payment method state
  String paymentMethod = 'készpénz'; // 'bankkártya', 'PayPal', 'készpénz'
  final cardNameController = TextEditingController();
  final cardNumberController = TextEditingController();
  final cardExpiryController = TextEditingController();
  final cardCvvController = TextEditingController();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    countyController.dispose();
    cityController.dispose();
    houseNumberController.dispose();
    postalCodeController.dispose();
    cardNameController.dispose();
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCvvController.dispose();
    super.dispose();
  }

  int getTotal() {
    int total = 0;
    for (final book in widget.cart) {
      final price = int.tryParse(book['price'] ?? '0') ?? 0;
      final quantity = book['quantity'] as int;
      total += price * quantity;
    }
    return total;
  }

  void _placeOrder() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A kosár üres.')));
      return;
    }
    // If bank card selected, validate card fields
    if (paymentMethod == 'bankkártya') {
      final cardNum = cardNumberController.text.replaceAll(' ', '');
      final cvv = cardCvvController.text.trim();
      final expiry = cardExpiryController.text.trim();
      final name = cardNameController.text.trim();
      // Basic validation: name present, card number length between 12 and 16,
      // expiry length between 3 and 4, CVV exactly 3 digits.
      if (name.isEmpty ||
          cardNum.length < 12 ||
          cardNum.length > 16 ||
          cvv.length != 3 ||
          expiry.length < 3 ||
          expiry.length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kérlek add meg a bankkártya adatait helyesen (név, 12–16 számjegy kártyaszám, lejárat MMYY max 4 számjegy, 3 jegyű CVV).',
            ),
          ),
        );
        return;
      }
    }
    // Simulate order placement - include payment method in message
    widget.onOrderPlaced();
    String payMsg = paymentMethod == 'bankkártya'
        ? 'Bankkártya'
        : (paymentMethod == 'PayPal' ? 'PayPal' : 'Készpénz');
    String masked = '';
    if (paymentMethod == 'bankkártya') {
      final num = cardNumberController.text.replaceAll(' ', '');
      if (num.length >= 4) masked = ' •••• ${num.substring(num.length - 4)}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rendelés leadva! Fizetés: $payMsg$masked')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendelés összesítés'),
        backgroundColor: const Color(0xFF4A2C2A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kosár tartalma',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.cart.isEmpty)
              const Text('A kosár üres.')
            else
              Column(
                children: [
                  ...widget.cart.map(
                    (book) => ListTile(
                      title: Text(book['title'] ?? ''),
                      subtitle: Text(
                        book['author_name'] ?? book['author'] ?? '',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              widget.onRemove(book);
                              setState(() {});
                            },
                          ),
                          Text('${book['quantity']}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              widget.onAdd(book);
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          if (book['price'] != null)
                            Text(
                              '${(int.tryParse(book['price'] ?? '0') ?? 0) * (book['quantity'] as int)} Ft',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Végösszeg: ${getTotal()} Ft',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const Text(
              'Szállítási adatok',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            hintText: 'Vezetéknév',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a vezetékneved.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            hintText: 'Keresztnév',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a keresztneved.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      hintText: 'Telefonszám',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Kérlek add meg a telefonszámod.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email cím',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Kérlek add meg az email címed.';
                      }
                      if (!v.contains('@')) {
                        return 'Érvényes email címet adj meg.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: countyController,
                          decoration: const InputDecoration(
                            hintText: 'Megye',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a megyét.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: cityController,
                          decoration: const InputDecoration(
                            hintText: 'Település',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a települést.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: houseNumberController,
                          decoration: const InputDecoration(
                            hintText: 'Házszám',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a házszámot.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: postalCodeController,
                          decoration: const InputDecoration(
                            hintText: 'Irányítószám',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg az irányítószámot.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // Payment method selection (készpénz / bankkártya / PayPal)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fizetési mód',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Készpénz'),
                    value: 'készpénz',
                    groupValue: paymentMethod,
                    onChanged: (v) =>
                        setState(() => paymentMethod = v ?? 'készpénz'),
                  ),
                  RadioListTile<String>(
                    title: const Text('Bankkártya'),
                    value: 'bankkártya',
                    groupValue: paymentMethod,
                    onChanged: (v) =>
                        setState(() => paymentMethod = v ?? 'bankkártya'),
                  ),
                  RadioListTile<String>(
                    title: const Text('PayPal'),
                    value: 'PayPal',
                    groupValue: paymentMethod,
                    onChanged: (v) =>
                        setState(() => paymentMethod = v ?? 'PayPal'),
                  ),
                  if (paymentMethod == 'bankkártya') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardNameController,
                      decoration: const InputDecoration(
                        hintText: 'Kártyabirtokos neve',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardNumberController,
                      decoration: const InputDecoration(
                        hintText: 'Kártyaszám',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cardExpiryController,
                            decoration: const InputDecoration(
                              hintText: 'Érvényesség (MMYY)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: cardCvvController,
                            decoration: const InputDecoration(
                              hintText: 'CVV',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C2A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rendelés leadása'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
