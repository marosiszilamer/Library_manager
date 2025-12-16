import 'package:flutter/material.dart';
import 'LogInPage.dart' as login;
import 'HomePage.dart' as home;
import 'package:fluttertoast/fluttertoast.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final loggedIn = prefs.getBool('loggedIn') ?? false;
  runApp(LibraryClient(initialLoggedIn: loggedIn));
}

class LibraryClient extends StatelessWidget {
  final bool initialLoggedIn;
  const LibraryClient({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Client',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initialLoggedIn ? home.HomePage() : login.LogInPage(),
    );
  }
}
