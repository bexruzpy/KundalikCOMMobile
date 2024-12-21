import 'package:flutter/material.dart';
import 'utils.dart';
import 'database.dart';

class DatasPage extends StatefulWidget {
  const DatasPage({super.key});

  @override
  _DatasPageState createState() => _DatasPageState();
}

class LoginItemWidget extends StatelessWidget {
  final String name;
  final String login;
  final String password;
  final VoidCallback onEdit;

  const LoginItemWidget({
    super.key,
    required this.name,
    required this.login,
    required this.password,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name, style: const TextStyle(fontSize: 28)),
        subtitle: Text(
          "login: $login\nparol: $password",
          style: const TextStyle(fontSize: 16),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _DatasPageState extends State<DatasPage> {
  Future<int> _fetchAllLoginsCount() async {
    final allLogins = await DatabaseHelper().getLogins();
    return allLogins.length;
  }

  Future<int> _fetchErrorLoginsCount() async {
    final errorLogins = await DatabaseHelper().getLoginsErrors();
    return errorLogins.length;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login Ma\'lumotlar'),
          bottom: TabBar(
            tabs: [
              FutureBuilder<int>(
                future: _fetchAllLoginsCount(),
                builder: (context, snapshot) {
                  final allNum = snapshot.data ?? 0;
                  return Tab(text: "Hammasi $allNum");
                },
              ),
              FutureBuilder<int>(
                future: _fetchErrorLoginsCount(),
                builder: (context, snapshot) {
                  final errNum = snapshot.data ?? 0;
                  return Tab(text: 'Paroli xatolar $errNum');
                },
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: DatabaseHelper().getLogins(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Xato: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Ma\'lumot yo\'q'));
                    }

                    final allLogins = snapshot.data!;
                    return ListView(
                      children: allLogins.entries.map((entry) {
                        final loginData = entry.value;
                        return LoginItemWidget(
                          name: loginData['name'] ?? '-',
                          login: loginData['login'],
                          password: loginData['password'],
                          onEdit: () {
                            showEditPopup(
                              context,
                              loginData['name'],
                              loginData['login'],
                              loginData['password'],
                              setState,
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                FutureBuilder<Map<String, Map<String, dynamic>>>(
                  future: DatabaseHelper().getLoginsErrors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Xato: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('Xato loginlar mavjud emas'));
                    }

                    final errorLogins = snapshot.data!;
                    return ListView(
                      children: errorLogins.entries.map((entry) {
                        final loginData = entry.value;
                        return LoginItemWidget(
                          name: loginData['name'] ?? '-',
                          login: loginData['login'],
                          password: loginData['password'],
                          onEdit: () {
                            showEditPopup(
                              context,
                              loginData['name'],
                              loginData['login'],
                              loginData['password'],
                              setState,
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
            Positioned(
              bottom: 50,
              right: 30,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 0, 13, 95),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 50,
                  onPressed: () {
                    showAddPopup(context, setState);
                  },
                  icon: const Icon(Icons.add),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
