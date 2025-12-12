/*
class HomePage extends StatelessWidget {
  const HomePage({super.key});

   Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kezdőoldal')),
      body: Center(
        child: FilledButton(
          onPressed: () => _logout(context),
          child: const Text('Kijelentkezés'),
        ),
      ),
    );
  }
}
*/
