import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _confirmLNController = TextEditingController();
  final TextEditingController _confirmFNController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _confirmPassController.dispose();
    _confirmLNController.dispose();
    _confirmFNController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Itt jöhet a regisztrációs logika, pl. HTTP kérés a szerver felé

    setState(() => _isLoading = true);
    try {
      // Itt jönne a valódi regisztrációs hívás (pl. Firebase vagy API)
      await Future.delayed(const Duration(milliseconds: 800));

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Példa: sikeres regisztráció, ha nem üres
      if (email.isNotEmpty && password.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sikeres regisztráció!')),
          );
          Navigator.of(context).pop(); // vissza a LoginPage-re
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Regisztrációs hiba: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg az email címet';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return 'Nem érvényes email formátum';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Add meg a jelszót';
    if (v.length < 6) return 'Legalább 6 karakter szükséges';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'A jelszavak nem egyeznek';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regisztráció')),
      body: Center(child: Text('Regisztrációs oldal tartalma ide kerül')),
    );
  }
}
