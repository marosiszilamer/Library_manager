import 'package:flutter/material.dart';
import '../services/users_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserService _service = UserService();
  late Future<List<User>> _users;

  @override
  void initState() {
    super.initState();
    _users = _service.fetchUsers();
  }

  void _refresh() {
    setState(() {
      _users = _service.fetchUsers();
    });
  }

  void _showUserForm({User? user}) {
    final TextEditingController usernameCtrl = TextEditingController(
      text: user?.username ?? '',
    );
    final TextEditingController emailCtrl = TextEditingController(
      text: user?.email ?? '',
    );
    final TextEditingController regCtrl = TextEditingController(
      text: user?.reg_date ?? '',
    );
    final TextEditingController lastLogInCtrl = TextEditingController(
      text: user?.last_login ?? '',
    );
    final TextEditingController passwordCtrl = TextEditingController();
    String role = user?.role ?? 'customer';
    bool isActive = user?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Add User' : 'Edit User'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: regCtrl,
                decoration: InputDecoration(labelText: 'Registration Date'),
              ),
              TextField(
                controller: lastLogInCtrl,
                decoration: InputDecoration(labelText: 'Last Login'),
              ),
              if (user == null)
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              DropdownButton<String>(
                value: role,
                items: ['customer', 'admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => role = val!),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user == null) {
                await _service.createUser(
                  usernameCtrl.text,
                  emailCtrl.text,
                  passwordCtrl.text,
                  role,
                );
              } else {
                await _service.updateUser(
                  user.userId,
                  usernameCtrl.text,
                  emailCtrl.text,
                  role,
                  isActive,
                );
              }
              Navigator.pop(context);
              _refresh();
            },
            child: Text(user == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(int userId) async {
    await _service.deleteUser(userId);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<User>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: ListTile(
                  title: Text(u.username),
                  minVerticalPadding: 10,
                  subtitle: Text(
                    "${u.email}\nRegistered: ${u.reg_date}\nLast Login: ${u.last_login}\nActive: ${u.isActive ? 'Yes' : 'No'}\nRole: ${u.role}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => _showUserForm(user: u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(u.userId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
