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

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showRegister = false;
  bool loggedIn = false;
  bool isAdmin =
      false; // simple flag to show admin content when logged in as admin
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
  // Books/search state
  bool showBooks = false;
  final searchController = TextEditingController();
  List<Map<String, String>> books = [
    {'title': 'A kis herceg', 'author': 'Antoine de Saint-Exupéry'},
    {'title': '1984', 'author': 'George Orwell'},
    {'title': 'A Gyűrűk Ura', 'author': 'J.R.R. Tolkien'},
    {'title': 'A kód', 'author': 'Dan Brown'},
  ];

  @override
  void dispose() {
    // dispose all controllers
    // loginEmailController removed; dispose other controllers below
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
      // determine which fields are missing/invalid for a clearer message
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
      // after login, show the books search page
      showBooks = true;
      // for demo: if username contains "admin", treat as admin
      isAdmin = userEmail.contains('admin');
    });
  }

  void _logout() {
    setState(() {
      loggedIn = false;
      userEmail = '';
      isAdmin = false;
    });
  }

  void _register() {
    // validate form
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    // check password match
    if (registerPasswordController.text != registerConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A megadott jelszavak nem egyeznek.')),
      );
      return;
    }

    setState(() {
      // greet by the registered username
      userEmail = registerUsernameController.text.trim();
      loggedIn = true;
      isAdmin = userEmail.contains('admin');
    });
  }

  Future<Map<String, String>?> _showAddBookDialog() async {
    final titleC = TextEditingController();
    final authorC = TextEditingController();
    final imageC = TextEditingController();

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
                // simple inline validation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cím és szerző megadása kötelező'),
                  ),
                );
                return;
              }
              final map = <String, String>{'title': title, 'author': author};
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
          // Background image (use local asset)
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

          // Dim overlay to make boxes readable
          Positioned.fill(
            child: Container(color: Color.fromRGBO(0, 0, 0, 0.25)),
          ),

          // Top bar (now can expand to include search when books view is active)
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
                  // Try to load local asset; fallback to text if missing
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/librarylogo.png',
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
                  // When viewing books show the search input in the top bar
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

          // Center content
          Positioned.fill(
            top: topBarHeight,
            child: Center(
              child: loggedIn
                  ? (showBooks ? _buildBooksPage() : _buildLoggedInContent())
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
          // Login box
          Visibility(
            visible: !showRegister,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D0), // pale warm brown/orange
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

          // Register box
          const SizedBox(height: 12),
          Visibility(
            visible: showRegister,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D0), // pale warm brown/orange
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

  Widget _buildLoggedInContent() {
    return Container(
      width: 700,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.25), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Üdvözöllek, $userEmail!',
                style: const TextStyle(fontSize: 18),
              ),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A2C2A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kijelentkezés'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAdmin) ...[
            const Text('Admin Felület', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text('Üdvözlünk, admin felhasználó!'),
          ] else ...[
            const Text('Felhasználói felület', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text('Üdvözlet, átlag felhasználó!'),
          ],
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
    // Large white content area below the top bar with a grid of small book cards
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
          // Header row with title and admin add button
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

          // Big results area
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
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Image / cover area
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
                                child:
                                    (b['image'] != null &&
                                        b['image']!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                        child: Image.network(
                                          b['image']!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 140,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.book,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.book,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  ],
                                ),
                              ),
                            ],
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
