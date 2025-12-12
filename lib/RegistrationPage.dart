import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmLNController = TextEditingController();
  final TextEditingController _confirmFNController = TextEditingController();
  final TextEditingController _confirmPhoneNumController =
      TextEditingController();
  final TextEditingController _confirmAddrController = TextEditingController();
  final TextEditingController _confirmCityController = TextEditingController();

  final TextEditingController _confirmPostalCodeController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  @override
  void dispose() {
    final formKey = GlobalKey<FormState>();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _confirmPassController.dispose();
    _confirmLNController.dispose();
    _confirmFNController.dispose();
    _confirmPhoneNumController.dispose();
    _confirmAddrController.dispose();
    _confirmCityController.dispose();
    _confirmPostalCodeController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
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

  String? _validateUserName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a felhasznalonevedet';
    if (v.length < 6) return 'Legalább 6 karakter szükséges';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg az email címet';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(v)) return 'Nem érvényes email formátum';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a jelszót';
    if (v.length < 6) return 'Legalább 6 karakter szükséges';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) return 'A jelszavak nem egyeznek';
    return null;
  }

  String? _validateFirstName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a keresztnevedet';
    final emailRegex = RegExp('^[A-Z][a-z]+\$');
    if (!emailRegex.hasMatch(v)) return 'Nem érvényes keresztnev formátum';
    return null;
  }

  String? _validateLastName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a vezetéknevedet';
    final emailRegex = RegExp('^[A-Z][a-z]+\$');
    if (!emailRegex.hasMatch(v)) return 'Nem érvényes vezetéknév formátum';
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a telefonszámodat';
    final emailRegex = RegExp('^[+]?[0-9]?[0-9]{10}\$');
    if (!emailRegex.hasMatch(v)) return 'Nem érvényes telefonszám formátum';
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a lakcímedet';
    return null;
  }

  String? _validateCity(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a városodat';
    final emailRegex = RegExp('^[A-Z][a-z]*\$');
    if (!emailRegex.hasMatch(v)) return 'Nem érvényes város formátum';
    return null;
  }

  String? _validatePostalCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add meg a postai irányítószámodat';
    final emailRegex = RegExp('^[0-9]{6}\$');
    if (!emailRegex.hasMatch(v)) return 'Nem érvényes iranyitoszam formátum';
    return null;
  }

  Future<void> _onRegistration() async {
    Navigator.of(context).pop(); // Vissza a bejelentkezési oldalra
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vissza a bejelentkezéshez')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Regisztráció ',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  //Form
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        //felhasznalonev
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Felhasználónév',
                            hintText: 'pl. username',
                            border: OutlineInputBorder(),
                          ),

                          validator: _validateUserName,
                        ),

                        //jelszo
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          keyboardType: TextInputType.text,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Jelszó',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Jelszó megjelenítése'
                                  : 'Jelszó elrejtése',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validatePassword,
                          autofillHints: const [AutofillHints.password],
                        ),

                        /*jelszo megerositese*/
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPassController,
                          obscureText: _obscurePasswordConfirm,
                          decoration: InputDecoration(
                            labelText: 'Jelszó megerősítése',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              tooltip: _obscurePasswordConfirm
                                  ? 'Jelszó megjelenítése'
                                  : 'Jelszó elrejtése',
                              icon: Icon(
                                _obscurePasswordConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePasswordConfirm =
                                    !_obscurePasswordConfirm,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateConfirm,
                          autofillHints: const [AutofillHints.password],
                        ),

                        //email
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email cím',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                        ),

                        //First Name
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmFNController,
                          decoration: InputDecoration(
                            labelText: 'First Name',

                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateFirstName,
                          autofillHints: const [AutofillHints.givenName],
                        ),

                        //Last Name
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmLNController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateLastName,
                          autofillHints: const [AutofillHints.familyName],
                        ),

                        //Phone number
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPhoneNumController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validatePhoneNumber,
                          autofillHints: const [AutofillHints.telephoneNumber],
                        ),

                        //Address
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmAddrController,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateAddress,
                          autofillHints: const [
                            AutofillHints.streetAddressLine1,
                          ],
                        ),

                        //City
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmCityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateCity,
                          autofillHints: const [AutofillHints.addressCity],
                        ),

                        //Postal Code
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPostalCodeController,
                          decoration: InputDecoration(
                            labelText: 'Postal Code',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validatePostalCode,
                          autofillHints: const [AutofillHints.postalCode],
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _onRegistration,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Regisztráció'),
                          ),
                        ),
                      ],
                    ),
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
