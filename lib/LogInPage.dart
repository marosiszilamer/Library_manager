import 'dart:convert';
import 'RegistrationPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class LogInPage extends StatefulWidget {
  @override
  _LogInPageState createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _formKey = GlobalKey<FormState>();
  final user = TextEditingController();
  final pass = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      var url = Uri.parse('http://192.168.1.7:80/library_api/client_login.php');
      var response = await http.post(
        url,
        body: {'username': user.text, 'password': pass.text},
      );
      if (response.statusCode != 200) {
        throw Exception('Hálózati hiba: ${response.statusCode}');
      }
      var data = json.decode(response.body);
      final success;

      if (data == "Success") {
        success = true;
      } else {
        success = false;
      }
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hibás email vagy jelszó')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bejelentkezési hiba: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateUsername(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Add meg a felhasznalonevedet';
    if (v.length < 6) return 'Legalább 6 karakter szükséges';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Add meg a jelszót';
    if (v.length < 6) return 'Legalább 6 karakter szükséges';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Bejelentkezés',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: user,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Felhasználónév',
                            hintText: 'pl. username',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),

                          validator: _validateUsername,
                          autofillHints: const [AutofillHints.username],
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: pass,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Jelszó',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Jelszó megjelenítése'
                                  : 'Jelszó elrejtése',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validatePassword,
                          autofillHints: const [AutofillHints.password],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _onLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Belépés'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => RegistrationPage()),
                      );
                    },
                    child: const Text('Nincs fiókod? Regisztrálj'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kezdőoldal')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text('Sikeres bejelentkezés!'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LogInPage()),
                );
              },
              child: const Text('Kijelentkezés'),
            ),
          ],
        ),
      ),
    );
  }
}
