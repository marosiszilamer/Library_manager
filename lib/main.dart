import 'package:flutter/material.dart';

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
  final registerPhoneController = TextEditingController();
  final registerConfirmController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  bool _loginObscure = true;
  bool showBooks = false;
  final searchController = TextEditingController();

  List<Map<String, String>> books = [
    {
      'title': 'A kis herceg',
      'author': 'Antoine de Saint-Exupéry',
      'description':
          'Egy kisfiú és egy különös bolygó története; filozofikus mese a barátságról és az emberi természet megértéséről.',
      'pages': '96',
      'language': 'magyar',
      'image': 'assets/a_kis_herceg_b1.jpg',
      'price': '2490',
    },
    {
      'title': '1984',
      'author': 'George Orwell',
      'description':
          'Dystópikus regény a totalitárius államról, ahol a nagy testvér figyel és az igazság manipulálható.',
      'pages': '328',
      'language': 'magyar',
      'image': '1984.jpg',
      'price': '3290',
    },
    {
      'title': 'A Gyűrűk Ura',
      'author': 'J.R.R. Tolkien',
      'description':
          'Egy epikus fantasy történet a hatalomról, barátságról és a bátorságról; Középfölde sorsa a tét.',
      'pages': '1216',
      'language': 'magyar',
      'image': 'a_gyuruk_ura.png',
      'price': '5990',
    },
    {
      'title': 'A kód',
      'author': 'Dan Brown',
      'description':
          'Izgalmas krimi tele rejtélyekkel, titkos társaságokkal és művészeti kódokkal.',
      'pages': '448',
      'language': 'magyar',
      'image': 'a_kod.png',
      'price': '4190',
    },
    {
      'title': 'Harry Potter és a bölcsek köve',
      'author': 'J.K. Rowling',
      'description':
          'Egy fiatal varázsló első éve a Roxfort Boszorkány- és Varázslóképző Szakiskolában, ahol barátságokat köt és veszélyes kalandokba keveredik.',
      'pages': '336',
      'language': 'magyar',
      'image': 'harry_potter_es_a_bolcsek_kove.jpg',
      'price': '3990',
    },
    {
      'title': 'Az öreg halász és a tenger',
      'author': 'Ernest Hemingway',
      'description':
          'Egy idős kubai halász küzdelme egy hatalmas marlinnal a tengeren; történet a kitartásról, büszkeségről és az emberi létről.',
      'pages': '128',
      'language': 'magyar',
      'image': 'az_oreg_halasz_es_a_tenger.jpeg',
      'price': '1990',
    },
    {
      'title': 'Sinistra körzet',
      'author': 'Ádám Bodor',
      'description':
          'Egy távoli sziget rejtélyes és nyomasztó története, ahol a valóság és a képzelet határai elmosódnak.',
      'pages': '256',
      'language': 'magyar',
      'image': 'sinistra_korzet.jpeg',
      'price': '3490',
    },
    {
      'title': 'Egri csillagok',
      'author': 'Gárdonyi Géza',
      'description':
          'Történelmi regény az egri vár hősi védelméről a törökök ellen, bátorságról és hazaszeretetről.',
      'pages': '512',
      'language': 'magyar',
      'image': 'egri_csillagok.jpg',
      'price': '2990',
    },
    {
      'title': 'A Pál utcai fiúk',
      'author': 'Molnár Ferenc',
      'description':
          'Két budapesti fiúbanda rivalizálása egy focilabda körül; történet a barátságról, árulásról és gyermekkor végéről.',
      'pages': '192',
      'language': 'magyar',
      'image': 'a_pal_utcai_fiuk.jpg',
      'price': '2290',
    },
  ];

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
    registerPhoneController.dispose();
    registerPasswordController.dispose();
    registerConfirmController.dispose();
    super.dispose();
  }

  void _login() {
    final valid = _loginFormKey.currentState?.validate() ?? false;
    if (!valid) {
      final missing = <String>[];
      if (loginUsernameController.text.trim().isEmpty) {
        missing.add('felhasználónév');
      }
      if (loginPasswordController.text.isEmpty) {
        missing.add('jelszó');
      }
      final message = missing.isEmpty
          ? 'Kérlek ellenőrizd a mezőket.'
          : 'Hiányzik: ${missing.join(', ')}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    setState(() {
      userEmail = loginUsernameController.text.trim();
      loggedIn = true;
      showBooks = true;
      isAdmin = userEmail.contains('admin');
    });
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
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    if (registerPasswordController.text != registerConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A megadott jelszavak nem egyeznek.')),
      );
      return;
    }
    setState(() {
      userEmail = registerUsernameController.text.trim();
      loggedIn = true;
      isAdmin = userEmail.contains('admin');
    });
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
                          controller: registerPhoneController,
                          decoration: const InputDecoration(
                            hintText: 'Telefonszám',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kérlek add meg a telefonszámod.';
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
      return t.contains(query) || a.contains(query);
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
                                            b['author'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
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

class BookDetailPage extends StatelessWidget {
  final Map<String, String> book;
  final void Function(Map<String, String> book) addToCart;
  final bool inCart;

  const BookDetailPage({
    super.key,
    required this.book,
    required this.addToCart,
    this.inCart = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book['title'] ?? 'Könyv'),
        backgroundColor: const Color(0xFF4A2C2A),
      ),
      body: Center(
        child: Container(
          width: 900,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      book['author'] ?? '',
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
                    const SizedBox(height: 12),
                    Text(
                      book['description'] ?? 'Nincs leírás',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (book['pages'] != null) ...[
                          const Icon(Icons.menu_book, size: 16),
                          const SizedBox(width: 6),
                          Text('${book['pages']} oldal'),
                          const SizedBox(width: 18),
                        ],
                        if (book['language'] != null) ...[
                          const Icon(Icons.language, size: 16),
                          const SizedBox(width: 6),
                          Text(book['language']!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: Text(inCart ? 'Már a kosárban' : 'Kosárba'),
          style: ElevatedButton.styleFrom(
            backgroundColor: inCart ? Colors.grey : const Color(0xFF4A2C2A),
            foregroundColor: Colors.white,
          ),
          onPressed: inCart
              ? null
              : () {
                  addToCart(book);
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
                      subtitle: Text(book['author'] ?? ''),
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

  const FavoritesDialog({
    super.key,
    required this.favorites,
    required this.onRemove,
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
                      subtitle: Text(book['author'] ?? ''),
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
    // Simulate order placement
    widget.onOrderPlaced();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Rendelés leadva!')));
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
                      subtitle: Text(book['author'] ?? ''),
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
            const SizedBox(height: 24),
            const Text(
              'A rendelés leadását követően a fizetés csak készpénzzel megvalósítható.',
              style: TextStyle(fontSize: 14, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Rendelés véglegesítése'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
